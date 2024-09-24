# bashargs

Parser for bash script args and bash function args.

## Run sample script

```bash
./bashargs_sample.sh -a true --efg false abcdefg hijklmn
```

## Usage

### Initializing

If you want to parse arguments in a bash script, please initialize it with the following command.

```bash
bargs::init_global
```

It defines the following global variables.

* BARGS_LABEL=""
* declare -A BARGS_OPTION_LABEL
* declare -A BARGS_OPTION_SHORT
* declare -A BARGS_OPTION_LONG
* declare -A BARGS_TYPE
* declare -A BARGS_REQUIRED
* declare -A BARGS_HELP
* declare -A BARGS_DEFAULT
* declare -A BARGS_STORE
* declare -A BARGS_VALUE
* declare -a BARGS_ARG

On the other hand, if you want to parse arguments in a bash function, please initialize it with the following command inside the function.

```bash
bargs::init_local
```

It defines the following local variables in the function.

 * local BARGS_LABEL=""
 * local -A BARGS_OPTION_LABEL
 * local -A BARGS_OPTION_SHORT
 * local -A BARGS_OPTION_LONG
 * local -A BARGS_TYPE
 * local -A BARGS_REQUIRED
 * local -A BARGS_HELP
 * local -A BARGS_DEFAULT
 * local -A BARGS_STORE
 * local -A BARGS_VALUE
 * local -a BARGS_ARG

### Definition of arguments

You can define the arguments with the ``bargs::add_option`` command.
This command takes the following arguments.

* arg1: label (required)
  * Argument identifier. You can specify any string without space.
  * ex: ``ARG_PORT``, ``ARG_HOST`` etc.
* arg2: option name (required)
  * You can specify option names that start with "-" or "--".
  * ex: ``-p``, ``--port``, ``-h``, ``--host`` etc.
* arg3: type (required)
  * type can be one of: ``string``, ``int``, ``bool``
* arg4: required (required)
  * If true, an error will occur if this option is not specified in the arguments.
* arg5: help (required)
  * This option's help message.
  * You can show usage with the ``bargs::usage``` command.
* arg6: store (required)
  * In the case of "none," the argument must be given a value.
  * In the case of "true" or "false," the argument does not take a value.
  * Setting it to true means that the value will be true if the option is specified, and false means the opposite.If you specify true or false, you must set the type to bool.
* arg7: default value (optional)
  * If the option is not specified, this value will be used.
  * If arg4(required) is false and no default value is set, an empty string will be automatically assigned for type string, 0 for type int, and false for type bool.

You can define a argument alias in the following way.

```bash
bargs::add_alias "label" "option"
```

For example, you can define an argument alias for the option ``-p`` as ``-port``.

```bash
bargs::add_option "ARG_PORT" "-p" "int" "true" "port number" "none"
bargs::add_alias "ARG_PORT" "--port"
```

``bargs::show_all_option`` shows all defined arguments.

(ex)
```
ARG_PORT,-p,--port,int,true,"port number",none,""
ARG_HOST,-h,--host,string,false,"host name",none,"localhost"
```

``bargs::show_all_value`` shows all labels and values.

(ex)
```
ARG_PORT=80
ARG_HOST=localhost
```


### Parsing arguments

After defining the arguments, you can parse them using the following command.

```
bargs::parse "$@"
```

### Extracting a value

You can extract a value using the following command.

```
bargs::get "label"
```

### Update a value

You can update a value using the following command.

```
bargs::set_value "label" "new value"
```

### Delete a value

You can delete a value using the following command.

```
bargs::del_value "label"
```

If value is deleted, an empty string will be automatically assigned for type string, 0 for type int, and false for type bool.
The label itself cannot be removed.

### Remaining arguments.

Any remaining arguments passed that are not options will be assigned to the BARGS_ARG array.

For example args ``-a 1 -b 2 --c 3 ddd eee fff`` will be assigned to ``BARGS_ARG=(ddd eee fff)``.

If "--" is passed as an argument, all subsequent arguments will also be assigned to the BARGS_ARG array.

For example args ``-a 1 -- -b 2 --c 3 ddd eee fff`` will be assigned to ``BARGS_ARG=(-b 2 --c 3 ddd eee fff)``.

### Special options

-h, --help, -v, and --version are reserved. If -h or --help is passed as an argument, bashargs will automatically call show_help() and terminate the program. Similarly, if -v or --version is passed, it will call show_version() and exit. Therefore, it's useful to define both functions in advance before calling bargs::parse.

### Validation

If a non-integer value is passed to an option of type int, or a value other than true or false is passed to an option of type bool, it will raise an error.Additionally, an error will occur if any options other than those defined are passed.

### Debug

If the environment variable BARGS_DEBUG="true", bashargs will output debugging information.