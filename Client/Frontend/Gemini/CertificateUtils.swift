import Shared
import OpenSSL

private let log = Logger.browserLogger

class CertificateError: MaybeErrorType {
    let internalDescription: String
    var description: String {
        "Certificate error: \(internalDescription)"
    }

    init(_ internalDescription: String) {
        self.internalDescription = internalDescription
    }
}

struct CertificateUtilsResult {
    let data: Data
    let fingerprint: String
}

class CertificateUtils {

    static func toIdentity(data : Data) -> SecIdentity? {
        let (id, _, sanityCheck) = parseKeyChainItems(data: data)

        switch sanityCheck {
        case errSecSuccess:
            break
        case errSecUnimplemented:
            log.error("not implemented")
        case errSecIO:
            log.error("I/O error")
        case errSecOpWr:
            log.error("File already open with write permission")
        case errSecParam:
            log.error("One or more parameters passed to a function were not valid")
        case errSecAllocate:
            log.error("Failed to allocate memory")
        case errSecUserCanceled:
            log.error("User canceled the operation")
        case errSecBadReq:
            log.error("Bad parameter or invalid state for operation")
        case errSecInternalComponent:
            log.error("Internal Component")
        case errSecNotAvailable:
            log.error("Not Available")
        case errSecDuplicateItem:
            log.error("Duplicate Item")
        case errSecItemNotFound:
            log.error("Item Not Found")
        case errSecInteractionNotAllowed:
            log.error("Interaction Not Allowed")
        case errSecDecode:
            log.error("Decode error")
        case errSecAuthFailed:
            log.error("Auth Failed")
        default:
            log.error("Unknown items")
        }
        return id
    }

    static func createCert(days: Int, name: String) -> CertificateUtilsResult? {
        CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON)
        OpenSSL_add_all_algorithms()
        SSL_load_error_strings()
        ERR_load_CRYPTO_strings()

        let pk = EVP_PKEY_new()!
        let cert = X509_new()!
        defer {
            X509_free(cert)
            EVP_PKEY_free(pk)
        }

        var rsa = RSA_new()
        let bn = BN_new()

        defer {
            RSA_free(rsa)
            BN_free(bn)
        }

        BN_set_word(bn, 0x10001);
        RSA_generate_key_ex(rsa, 2048, bn, nil)

        EVP_PKEY_assign(pk, EVP_PKEY_RSA, &rsa)
        X509_set_version(cert, 2)
        ASN1_INTEGER_set(X509_get_serialNumber(cert), 0)

        let notBefore = ASN1_TIME_new()
        let notAfter = ASN1_TIME_new()
        defer {
            ASN1_TIME_free(notBefore)
            ASN1_TIME_free(notAfter)
        }

        ASN1_TIME_set(notBefore, 0)
        X509_set1_notBefore(cert, notBefore)
        ASN1_TIME_set(notAfter, 60*60*24*days)
        X509_set1_notAfter(cert, notAfter)
        EVP_PKEY_set1_RSA(pk, rsa)
        X509_set_pubkey(cert, pk)

        let subject = X509_get_subject_name(cert)!
        "CN".data(using: .ascii)!.withUnsafeBytes({ (cn) in
            name.data(using: .utf8)!.withUnsafeBytes({ (cn_name) in
                X509_NAME_add_entry_by_txt(subject, cn, MBSTRING_ASC, cn_name, -1, -1, 0)
            })
        })

        X509_set_issuer_name(cert, subject)
        X509_sign(cert, pk, EVP_sha256())

        let certName = UnsafeMutablePointer(mutating: (name as NSString).utf8String)!
        let pass = UnsafeMutablePointer(mutating: ("" as NSString).utf8String)!
        guard let p12 = PKCS12_create(pass, certName, pk, cert, nil, 0, 0, 0, 0, 0) else {
            log.error("could not create p12 certififate")
            ERR_print_errors_fp(stderr)
            return nil
        }
        defer {
            PKCS12_free(p12)
        }

        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(Bytes.generateGUID())
        fileManager.createFile(atPath: url.path, contents: nil, attributes: nil)
        guard let fileHandle = FileHandle(forWritingAtPath: url.path) else {
            log.error("Cannot open file handle: \(url.path)")
            return nil
        }
        let p12File = fdopen(fileHandle.fileDescriptor, "w")
        i2d_PKCS12_fp(p12File, p12)

        fclose(p12File)
        fileHandle.closeFile()

        let data = try! Data(contentsOf: url)

        try! fileManager.removeItem(atPath: url.path)

        let (_, secCertM, _) = parseKeyChainItems(data: data)
        guard let secCert = secCertM else {
            return nil
        }

        return CertificateUtilsResult(data: data, fingerprint: secCert.fingerprint().joined(separator: ":"))
    }

    fileprivate static func parseKeyChainItems(data: Data) -> (SecIdentity?, SecCertificate?, OSStatus) {
        var rawItems: CFArray?
        let options: NSMutableDictionary = [kSecImportExportPassphrase as NSString: ""]
        let sanityCheck = SecPKCS12Import(NSData(data: data), options, &rawItems)

        if sanityCheck != errSecSuccess || CFArrayGetCount(rawItems) == 0 {
            return (nil, nil, sanityCheck)
        }

        let items = rawItems! as! Array<Dictionary<String, Any>>
        let dict = items[0]
        let identity = dict[String(kSecImportItemIdentity)] as! SecIdentity?
        let certArray = dict["chain"] as! [SecCertificate]

        return (identity, certArray[safe: 0], sanityCheck)
    }
}
