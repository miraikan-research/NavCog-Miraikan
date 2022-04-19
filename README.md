# Miraikan-NavCog

## Developer Certificate of Origin (DCO)

The developer need to add a Signed-off-by statement and thereby agrees to the DCO, which you can find below. You can add either -s or --signoff to your usual git commit commands. If Signed-off-by is attached to the commit message, it is regarded as agreed to the Developer's Certificate of Origin 1.1.

https://developercertificate.org/

```
Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the
    best of my knowledge, is covered under an appropriate open
    source license and I have the right under that license to
    submit that work with modifications, whether created in whole
    or in part by me, under the same open source license (unless
    I am permitted to submit under a different license), as
    Indicated in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including
    all personal information I submit with it, including my
    sign-off) is maintained indefinitely and may be redistributed
    consistent with this project or the open source license(s)
    involved.

```

## Prerequisite
1. install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2. Xcode Command Line Tools setting: Xcode -> Preferences -> Locations
![Screen Shot 2021-11-04 at 9 05 21](https://user-images.githubusercontent.com/87963922/140235738-b0d1ed2d-812b-4880-b0f0-1a32fc959f0e.png)
3. If you got problem with Build step 3, please try to install **Ruby** following [this guideline](https://zenn.dev/osuzuki/articles/a535b2840bbea3).

## Build
1. install [Carthage](https://github.com/Carthage/Carthage): `brew install carthage`
2. In the project directory, run `carthage update --platform iOS`.
3. install for OpenCV, run `brew install cmake`.
4. install [Cocoapods](https://cocoapods.org/): `sudo gem install cocoapods`
5. In the project directory, run `pod install`
6. Open NavCog3.xcworkspace
7. Build NavCog3 target with Xcode.

**Additional configuration**

If you got an error with Carthage path, please check about the script below, in case that it is different on your device.
Command to find the correct path: `which carthage`.
![Screen Shot 2021-11-01 at 15 21 41](https://user-images.githubusercontent.com/87963922/139630263-6831379c-df14-4d09-84ea-8c8fb6408803.png)


\# if you archive the app for AppStore, `Frameworks` directory in `Carthage/Build/iOS/HLPDialog.framework` should be removed.

----
## About

- "Miraikan" - created by Miraikan 
- "NavCog3.xcodeproj", "NavCog3", "NavCogFP", "NavCogPreview", "NavCogTools" - cloned from NavCog - HULOP project. [About HULOP](https://github.com/hulop/00Readme)

## Icons
Icons in NavCogFP are from [https://github.com/IBM-Design/icons](https://github.com/IBM-Design/icons)

Icons in NavCogMiraikan tabs are from [https://icons8.com](https://icons8.com)

## License for codes from HULOP project
[MIT](https://opensource.org/licenses/MIT): files under "NavCog3.xcodeproj", "NavCog3", "NavCogFP", "NavCogPreview", "NavCogTools" and other files cloned from the NavCog - HULOP project. 

## License for Miraikan
[APL2.0](https://www.apache.org/licenses/LICENSE-2.0): This is for files under [Miraikan/](https://github.com/miraikan-research/NavCog-Miraikan/tree/miraikan/Miraikan) directory.

**Source Code Heading**

Before modifying NavCogMiraikan app, please create a **IDETemplateMacros.plist** file under either of directories below:
- **Project user data**: NavCog3.xcodeproj/xcuserdata/[username].xcuserdatad/IDETemplateMacros.plist. - using that location would cover a specific project for just a single developer.
- **Project shared data**: NavCog3.xcodeproj/xcshareddata/IDETemplateMacros.plist- using that location would cover a specific project for the whole team using the workspace.
- **Workspace user data**: NavCog3.xcworkspace/xcuserdata/[username].xcuserdatad/IDETemplateMacros.plist.- using that location would cover all projects in the workspace for just a single developer.
- **Workspace shared data**: NavCog3.xcworkspace/xcshareddata/IDETemplateMacros.plist. - using that location would cover all projects in the workspace for the whole team using the workspace.
- **User Xcode data**: ~/Library/Developer/Xcode/UserData/IDETemplateMacros.plist - for all projects edited by the local user.

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>FILEHEADER</key>
    <string>
[Content]
[Content ending]</string>
</dict>
</plist>
```

You can use different variables like DATE and FILENAME, but the basic content should be:

```
/*******************************************************************************
 * Copyright (c) 2021 © Miraikan - The National Museum of Emerging Science and Innovation  
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/
```

Here is the reference for the variables: [TEXT MACROS](https://help.apple.com/xcode/mac/11.4/index.html?localePath=en.lproj#/dev7fe737ce0)


## README
The NavCog-Miraikan app is created specifically for Miraikan usage. In addition to navigation, it also includes the functions for Event Notifications, Exhibition Details and User Profiles.

This app is using Human Scale Localization Platform library, which is intended solely for use with an Apple iOS product and intended to be used in conjunction with officially licensed Apple development tools and further customized and distributed under the terms and conditions of your licensed Apple developer program.

	
