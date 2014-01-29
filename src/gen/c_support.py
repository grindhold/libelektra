from gen_support import *

#todo: duplicate
def funcname(key):
    if key.startswith('/'):
        return funcpretty(key[1:])
    elif key.startswith('user/'):
        return funcpretty(key[5:])
    elif key.startswith('system/'):
        return funcpretty(key[7:])
    else:
        raise Exception("invalid keyname " + key)

def funcpretty(key):
    return key.replace('/','_').replace('#','')

def userkey(key):
    """Return the key name within user/"""
    if key.startswith('/'):
        return "user"+key
    elif key.startswith('user/'):
        return key
    elif key.startswith('system/'):
        return "user"+key[6:]
    else:
        raise Exception("invalid keyname " + key)

def valof(info):
    """Return the default value for given parameter"""
    val = info["default"]
    type = info["type"]
    if type == "bool":
        if val == "true":
            return " = 1;"
        elif val == "false":
            return " = 0;"
    else:
        return " = "+val+";"

def typeof(info):
    """Return the type for given parameter"""
    type = info["type"]
    if type == "unsigned_int_32":
        return "uint32_t"
    elif type == "bool":
        return "int"
    elif type == "string":
        return "char*"
    elif isenum(info):
        return "enum " + enumname(info)
    else:
        return type
