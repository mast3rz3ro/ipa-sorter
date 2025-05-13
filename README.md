# iPA-Sorter
*An efficent utility for sorting and managing the iPA files (iOS App Bundle)*

## Description
*This utility helps in managing the iPA files by determining first the encryption status (cryptid) of the app,
 and parsing the app identifiers (e.g: bundle version) then using these informations to rename the app with 
so they appear in more reliable way.*

## When to use?
*This utility are meant for those who would like to keep backup of their downloaded apps in well sorted and organized way,
 especially for those who keeps backup for bunch of downloaded apps,
 another reason for using it is to quickly identify the encryption status (cryptid) of the certian app.*


### Installation for iOS users

1. Jailbreak is required
2. Open your package manager Sileo or Zebra then install: NewTerm and curl
3. Open NewTerm then copy and paste the following command:

```Bash
curl "https://raw.githubusercontent.com/mast3rz3ro/ipa-sorter/refs/heads/main/install.sh" | bash -
```

4. If you have faced any errors during the installation then feel free to file an issue here.


### How to use?
*After succuessfully installing iPA-Sorter you should be able to call it within NewTerm by entering ipa-sorter in NewTerm*

- You can start using ipa-sorter simply by passing the app path as following:

```Bash
% ipa-sorter /var/mobile/Media/someapp.ipa
```

- If you are not sure where you placed your apps then just pass the main user directory as follows:

```Bash
% ipa-sorter /var
```

*Note: iPA-Sorter is very safe on handling the files, the worst thing can happen is just losing the original filename of the app
 and this can be prevented by redirecting the proccess output into a file (e.g: `ipa-sorter someapp.ipa >>x.log`)
 this way you will keep a record where you can restore from the original apps names If needed.*
*Hint: Redirecting the proccess output is recommanded when proccessing huge list of apps.*

- The utility by default won't rename any apps, to enable app renaming you must enable it manually as following:

```Bash
% export rename_apps="yes"
% ipa-sorter /var/mobile/Media/someapp.ipa
```

*Note: this option will rename the apps while keeping them in thier own directory.*
*Hint: someapp.ipa will be renamed for example into: "Discord v5.4(1023)_unencrypted.ipa"
 or in case it's was encrypted into: "Discord v5.4(1023)_encrypted.ipa" (without qoutes).*

- You can specify a new directory for moving the renamed apps into as following:

```Bash
% export output_dir="/var/mobile/Media/MyAppsDir"
% export rename_apps="yes"
% ipa-sorter /var/mobile/Media/someapp.ipa
```

*Note: when the output_dir is set the apps will be grouped into two different folders.*
*Hint: this time encrypted apps will be renamed e.g into: "MyAppsDir/encrypted/appleid@icloud.com/Discord v5.4(1023).ipa"
 and for unencrypted apps into: "MyAppsDir/unencrypted/Discord v5.4(1023).ipa"*


### How to report an issue?

*You can report an issue by using the issues section [here](https://github.com/mast3rz3ro/ipa-sorter/issues),
 but please make sure to use the verbose mode to provide the neccessary informations about the issue.*


### Informations for Developers

- Required basic utils is following: grep, od, awk, unzip and 7z (maybe more)
- Required other utils is following: libplist and plget
- This utility is capable of determining the cryptid status for both `LC_ENCRYPTION_INFO` and `LC_ENCRYPTION_INFO_64` load commands.
- This utility can parse Mach-O headers without extracting the whole binary, 
 however in case of the app has an multiple binary it's will extract the binary into a temporary file then it's will continue parsing each binary header from there.
- To directly determine cryptid status of mach-o binary you should give it an macho extension before passing it e.g: binary.macho
- You can enable the verbose mode to help you debugging the utility.
- Currently does not support packing the uncompressed iPA files.
- Currently does not support auto installing on other systems (the iPA-Sorter installer).
- The code may require some cleanup for pure functional.


### Credits

*All used utils belongs to their own authors and contributors and an special thanks goes to @Nikias for helping me to learn more about the Mach-O load commands.*


### License

BSD 3-Clause
