# ast-visualizer
Technically, any vertical M-ary tree visualizer

![image](https://github.com/user-attachments/assets/72b2ca66-7fc2-4db9-91db-5e46ee81bc6f)

# Compiling

[install odin-lang](https://odin-lang.org/docs/install/)

If you're on Windows:  
1. run `compile.bat`   *(it runs `odin run .`)*

If you're on Linux:  
1. run `odin run .`

# Usage

The visualizer uses UDP sockets to communicate. So you will have to open up a socket and send text to port: `8779` on your `localhost`/`127.0.0.1`

The program uses a lisp-like syntax, so any text inside of parentheses followed, optionally, by more parentheses with text. 
Although `#` is a special character used in my amazing parsing algorithm! *dw bout it...*

If you wanted to make a tree such as:
```
  +
 / \
5   *
   / \
  4   $a
```
You would give it: `(+ (5) (* (4) ($a) ) )`

An example input: 
```cl
(root
  (cmd: String(C:/Windows/cmd.exe: String))
  (a: Long(add(2: Long)(2: Long)(*(54: Long)(+($a)($a)))(+(1: Long))))
  (b: Long(+(6: Long)(+(*(5: Long)(*($b)($a)))(+(2: Long)(1: Long)))))
  (c: Double(@($cmd)(/(6: Long)(2.452: Double)))))
```

## Example of how I produce the input to visualizer with Java

```Java

private static String zip(Ast ast) {
    StringBuilder b = new StringBuilder();
    
    b.append('(');
    
    if(ast == null) {
        b.append("null").append(')');
        return b.toString();
    }
    
    switch(ast) {
    case Ast.Root node -> {
        b.append("root");
        for(Ast child : node.children) b.append(zip(child));
    }
    case Ast.Func node -> {
        b.append(node.name);
        for(Ast child : node.args) b.append(zip(child));
    }
    case Ast.Var node -> b.append('$').append(node.name);
    }

    b.append(")");
    return b.toString();
}
```

I have now (literally 5 minutes, since finishing this README.md) realized that I could  just have printed this in the terminal and would have gotten the same thing...
