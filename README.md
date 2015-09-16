Freifunk Fulda - Site configuration
===================================

This repo holds the site configuration for the Freifunk Fulda build of gluon.


Repository structure
--------------------

The gluon version used to build the firmware is referenced as a git submodule.
To ensure that the submodule is initialized correctly, call ```git submodule update --init``` after a checkout.


Build the firmware
------------------

The firmware can be build using the ```./build.sh``` script contained in the repository.
To do a full build use the following commands:

```
./build.sh -c update -b snapshot -n b001
./build.sh -c download -b snapshot -n b001
./build.sh -c build -b snapshot -n b001
```


Upload and sign the firmware
----------------------------

To upload the firmware to the firmware repository, you can use the following command:

```
./build.sh -c upload -b snapshot -n 001
```

To sign already uploaded images, you can use the following command:

```
./sign.sh /path/to/your/private.key snapshot
```

