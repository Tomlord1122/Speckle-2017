# Speckle-2017 abclab

Help you run SPECCPU2017 systematically.

## How to use

``` bash
export SPEC_DIR=/home/tomlord/workspace/SPECCPU2017

# Go modify your config file, you can refer to riscv_tom_custom.cfg
# modify the label to your file config name %define label riscv_tom_custom  
# and compiler section and baseline flag section 

./gen_binaries_custom.sh --compile

```

After you run the script, you can see the binaries in the `build` directory.
And the runscript will be located in the each benchmark directory.
