/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension Tab {
    class ChangeUserAgent {
        // Track these in-memory only
        static var privateModeHostList = Set<String>()

        private static let file: URL = {
            let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return root.appendingPathComponent("changed-ua-set-of-hosts.xcarchive")
        } ()

        private static var baseDomainList: Set<String> = {
            if let hosts = NSKeyedUnarchiver.unarchiveObject(withFile: ChangeUserAgent.file.path) as? Set<String> {
                return hosts
            }
            return Set<String>()
        } ()

        static func clear() {
            try? FileManager.default.removeItem(at: Tab.ChangeUserAgent.file)
            baseDomainList.removeAll()
        }

        static func contains(url: URL) -> Bool {
            guard let baseDomain = url.baseDomain else { return false }
            return privateModeHostList.contains(baseDomain) || baseDomainList.contains(baseDomain)
        }
    }
}
