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

    static func toP12(data : Data) -> Maybe<[AnyObject]> {
        var items: CFArray?
        let options: NSMutableDictionary = [kSecImportExportPassphrase as NSString: ""]
        let sanityCheck = SecPKCS12Import(NSData(data: data), options, &items)

        if sanityCheck == errSecSuccess && CFArrayGetCount(items) > 0 {
            return Maybe(success: parseKeyChainItems(items!))
        }
        switch sanityCheck {
        case errSecSuccess:
            return Maybe(failure: CertificateError("no certificate"))
        case errSecUnimplemented:
            return Maybe(failure: CertificateError("not implemented"))
        case errSecIO:
            return Maybe(failure: CertificateError("I/O error"))
        case errSecOpWr:
            return Maybe(failure: CertificateError("File already open with write permission"))
        case errSecParam:
            return Maybe(failure: CertificateError("One or more parameters passed to a function were not valid"))
        case errSecAllocate:
            return Maybe(failure: CertificateError("Failed to allocate memory"))
        case errSecUserCanceled:
            return Maybe(failure: CertificateError("User canceled the operation"))
        case errSecBadReq:
            return Maybe(failure: CertificateError("Bad parameter or invalid state for operation"))
        case errSecInternalComponent:
            return Maybe(failure: CertificateError("Internal Component"))
        case errSecNotAvailable:
            return Maybe(failure: CertificateError("Not Available"))
        case errSecDuplicateItem:
            return Maybe(failure: CertificateError("Duplicate Item"))
        case errSecItemNotFound:
            return Maybe(failure: CertificateError("Item Not Found"))
        case errSecInteractionNotAllowed:
            return Maybe(failure: CertificateError("Interaction Not Allowed"))
        case errSecDecode:
            return Maybe(failure: CertificateError("Decode error"))
        case errSecAuthFailed:
            return Maybe(failure: CertificateError("Auth Failed"))
        default:
            return Maybe(failure: CertificateError("Unknown items: \(String(describing: items))"))
        }
    }

    static func createCert(days: Int, name: String) -> CertificateUtilsResult? {
        CRYPTO_mem_ctrl(CRYPTO_MEM_CHECK_ON)
        OPENSSL_add_all_algorithms_noconf()
        ERR_load_CRYPTO_strings()

        let pk = EVP_PKEY_new()!
        let cert = X509_new()!
        let rsa = RSA_generate_key(2048, UInt(RSA_F4), nil, nil)!
        EVP_PKEY_assign_wrapper(pk, rsa)

        X509_set_version(cert, 2)
        ASN1_INTEGER_set(X509_get_serialNumber(cert), 0)
        X509_gmtime_adj(cert.pointee.cert_info.pointee.validity.pointee.notBefore, 0)
        X509_gmtime_adj(cert.pointee.cert_info.pointee.validity.pointee.notAfter, 60*60*24*days)
        X509_set_pubkey(cert, pk)

        let subject = X509_get_subject_name(cert)!
        "CN".data(using: .ascii)!.withUnsafeBytes({ (cn) in
            name.data(using: .utf8)!.withUnsafeBytes({ (cn_name) in
                X509_NAME_add_entry_by_txt(subject, cn, MBSTRING_ASC, cn_name, -1, -1, 0)
            })
        })

//        let X509_check_private_key_result = X509_check_private_key(cert, pk)

        X509_set_issuer_name(cert, subject)
        X509_sign(cert, pk, EVP_sha256())

        let certName = UnsafeMutablePointer(mutating: (name as NSString).utf8String)!
        let pass = UnsafeMutablePointer(mutating: ("" as NSString).utf8String)!
        guard let p12 = PKCS12_create(pass, certName, pk, cert, nil, 0, 0, 0, 0, 0) else {
            log.error("could not create p12 certififate")
            ERR_print_errors_fp(stderr)
            return nil
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
        PKCS12_free(p12)
        X509_free(cert)
        EVP_PKEY_free(pk)
        fclose(p12File)
        fileHandle.closeFile()

        let data = try! Data(contentsOf: url)

        try! fileManager.removeItem(atPath: url.path)

        var items: CFArray?
        let options: NSMutableDictionary = [kSecImportExportPassphrase as NSString: ""]
        let sanityCheck = SecPKCS12Import(NSData(data: data), options, &items)

        guard sanityCheck == errSecSuccess && CFArrayGetCount(items) > 0 else {
            return nil
        }

        guard let secItem = parseKeyChainItems(items!)[safe: 1] else {
            return nil
        }
        let secCert = secItem as! SecCertificate

        return CertificateUtilsResult(data: data, fingerprint: secCert.fingerprint().joined(separator: ":"))
    }

    fileprivate static func parseKeyChainItems(_ keychainArray: NSArray) -> [AnyObject] {
        let dict = keychainArray[0] as! Dictionary<String,AnyObject>
        let identity = dict[String(kSecImportItemIdentity)] as! SecIdentity?

        let certArray:[AnyObject] = dict["chain"] as! [SecCertificate]

        var certChain:[AnyObject] = [identity!]

        for item in certArray {
            certChain.append(item)
        }
        return certChain
    }
}
