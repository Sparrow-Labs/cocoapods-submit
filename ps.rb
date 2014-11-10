handled_processes = []

while true
  processes = `ps ax`.split "\n"
  index = processes.shift.index /COMMAND/

  processes.map { |s| s[index..-1] }.each do |command|
    command = command.strip
    next if handled_processes.include? command

    handled_processes << command
    puts command
  end
  sleep 0.001
end

=begin
/Applications/Atom.app/Contents/Frameworks/Atom Helper.app/Contents/MacOS/Atom Helper --eval require('/Applications/Atom.app/Contents/Resources/app/node_modules/coffee-script/lib/coffee-script/coffee-script.js').register();^Jrequire('/Applications/Atom.app/Contents/Resources/app/src/coffee-cache.js').register();^Jrequire('/Applications/Atom.app/Contents/Resources/app/src/task-bootstrap.js');
(Atom Helper)
(lssave)
/System/Library/Frameworks/CoreServices.framework/Frameworks/Metadata.framework/Versions/A/Support/mdworker -s mdworker-bundle -c MDSImporterBundleFinder -m com.apple.mdworker.bundles
/usr/bin/ditto -V /Users/oliver/Library/Developer/Xcode/Archives/2014-11-10/SellSpotCompanion 10.11.14 10.16.xcarchive/Products/Applications/SellSpotCompanion.app /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app
(ditto)
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementsYm3 /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/SellSpotSDK.framework
codesign_allocate -i /private/var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/SellSpotSDK.framework/SellSpotSDK -o /private/var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/SellSpotSDK.framework/SellSpotSDK.cstemp -a armv7 24848 -a arm64 28448
(codesign)
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementsD0l /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftCore.dylib
(codesign_allocat)
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementscGY /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftCoreGraphics.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementssEK /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftCoreImage.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementsrR2 /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftDarwin.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementsUAE /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftDispatch.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementscaW /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftFoundation.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementsBYW /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftObjectiveC.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementswOn /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftSecurity.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementsj8N /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app/Frameworks/libswiftUIKit.dylib
/usr/bin/codesign -vvv --force --sign 41796A964CE9D664FB012A8A47ADDA2C22DED204 --preserve-metadata=identifier,resource-rules --entitlements /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/entitlementsVRN /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root/Payload/SellSpotCompanion.app
(rsync)
/Applications/Xcode.app/Contents/Developer/usr/bin/symbols -noTextInSOD -noDaemon -arch all -symbolsPackageDir /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Symbols /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/SellSpotSDK.framework/SellSpotSDK
(symbols)
/Applications/Xcode.app/Contents/Developer/usr/bin/symbols -noTextInSOD -noDaemon -arch all -symbolsPackageDir /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Symbols /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/SellSpotCompanion.app/SellSpotCompanion
/usr/bin/ditto -V -c -k --norsrc /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/Root /var/folders/nr/th1dm1g94d79dn7w2d1r3nxw0000gn/T/XCodeDistPipeline.bUI/SellSpotCompanion.ipa
/System/Library/PrivateFrameworks/FamilyControls.framework/Resources/parentalcontrolsd
automountd
(mdworker)
(parentalcontrols)
(zsh)
(git)
(tail)
(cat)
(mdwrite)
(SFLSharedPrefsTo)
/System/Library/PrivateFrameworks/SyncedDefaults.framework/Support/syncdefaultsd
(garcon)
pluginkit -a /Applications/Dropbox.app/Contents/PlugIns/garcon.appex
(pluginkit)
pluginkit -e use -i com.getdropbox.dropbox.garcon
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lssave 0
(SFLIconTool)
/Applications/Xcode.app/Contents/SharedFrameworks/DVTSourceControl.framework/Versions/A/XPCServices/com.apple.dt.Xcode.sourcecontrol.Git.xpc/Contents/MacOS/com.apple.dt.Xcode.sourcecontrol.Git
/Applications/Xcode.app/Contents/SharedFrameworks/DVTSourceControl.framework/Versions/A/XPCServices/com.apple.dt.Xcode.sourcecontrol.Subversion.xpc/Contents/MacOS/com.apple.dt.Xcode.sourcecontrol.Subversion
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/sourcekitd.framework/Versions/A/XPCServices/SourceKitService.xpc/Contents/MacOS/SourceKitService
/Applications/Xcode.app/Contents/SharedFrameworks/DVTSourceControl.framework/Versions/A/XPCServices/com.apple.dt.Xcode.sourcecontrol.WorkingCopyScanner.xpc/Contents/MacOS/com.apple.dt.Xcode.sourcecontrol.WorkingCopyScanner
/Applications/Xcode.app/Contents/Developer/usr/bin/svn info /Users/oliver/Development/SparrowLabs/sellspot --xml --no-auth-cache
/Applications/Xcode.app/Contents/Developer/usr/bin/git config --get remote.origin.url
/Applications/Xcode.app/Contents/Developer/usr/bin/git status --porcelain
(sh)
(clang)
(svn)
(ld)
git diff
less
(com.apple.iCloud)
=end
