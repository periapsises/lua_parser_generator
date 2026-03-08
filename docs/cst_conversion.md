# Converting CSTs

The raw output from the parser is a tree of nodes in which children are ordered in the same way they were in the rules.  
However, the tree is based on the flattened grammar which makes it harder for developers to use without a reference to how the parser was generated.  
Other issues with optional or list of zero or more items come because they contain an element which the developer has to manually check contains no tokens or sub nodes.

## The goal

A post-process step on the resulting CST is required to convert it into something closer to the original grammar.  
This means understanding how the rules are built, keeping track of what name they originally had and converting nodes into meaningful data such as lists.

### The cases to handle

The most straightforward conversion is with a rule containing only tokens:
```
a: X Y Z;
```

The processed tree would look like the following:
```
{
    type = "rule",
    X = { type = "token", value = "X" },
    Y = { type = "token", value = "Y" },
    Z = { type = "token", value = "Z" },
}
```

---

We can add some complexity by repeating the same token more than once.  
```
a: X Y Y Z;
```

In this case, the tokens appearing more than once become an array.
```
{
    type = "rule",
    X = { type = "token", value = "X" },
    Y = {
        [1] = { type = "token", value = "Y" },
        [2] = { type = "token", value = "Y" },
    },
    Z = { type = "token", value = "Z" },
}
```

---

Optional tokens falls under the same rules except it requires to specify if it is empty.
```
a: X Y? Z;
```

```
{
    type = "rule",
    X = { type = "token", value = "X" },
    Y = { type = "token", value = "", empty = true },
    Z = { type = "token", value = "Z" },
}
```

---

This becomes apparent with repeating tokens.  
For instance if there are three of the same token in a rule, and the second one is optional, we cannot just move the third into the second's position in the array.

```
a: X Y Y? Z Y;
```

```
{
    type = "rule",
    X = { type = "token", value = "X" },
    Y = {
        [1] = { type = "token", value = "Y" },
        [2] = { type = "token", value = "", empty = true },
        [3] = { type = "token", value = "Y" },
    },
    Z = { type = "token", value = "Z" },
}
```

---

We can apply a similar logic to tokens repeating either zero or more times or one or more times.
```
a: X Y+ Z;
```

Whether it's a minimum of zero or one times doesn't need to be handled differently as the difference will be the length of the array.
```
{
    type = "rule",
    X = { type = "token", value = "X" },
    Y = {
        [1] = { type = "token", value = "Y" },
        [2] = { type = "token", value = "Y" },
    },
    Z = { type = "token", value = "Z" },
}
```

---

When a repeating token becomes part of a group of already repeated tokens however, the generated array will live at the index the token appeared at in the rule.
```
a: X Y Z Y*;
```

```
{
    type = "rule",
    X = { type = "token", value = "X" },
    Y = {
        [1] = { type = "token", value = "Y" },
        [2] = {
            { type = "token", value = "Y" },
        },
    },
    Z = { type = "token", value = "Z" },
}
```

---

Complications arise when it comes to alternations because there a multiple ways it could be handled.  
What I think makes the most sense is to generate the resulting node with the same rules above for the specific alternative that applied.  
An extra `alt` value is stored in the node to specify which alternative was chosen (1-indexed).
```
a: X Y | X Z;
```

With the input `XY`:
```
{
    type = "rule",
    alt = 1,
    X = { type = "token", value = "X" },
    Y = { type = "token", value = "Y" },
}
```

And with `XZ`:
```
{
    type = "rule",
    alt = 2,
    X = { type = "token", value = "X" },
    Z = { type = "token", value = "Z" },
}
```

### Grouping

With groups, the same rules above apply but on the whole group as one.  
For this reason, any group present in a rule will be stored using a numerical index (1-indexed).

```
a: X (Y | Z);
```

In this example, the group `(Y | Z)` is assigned to index `[1]`.
```
{
    type = "rule",
    X = { type = "token", value = "X" },
    [1] = {
        alt = 2,
        Z = { type = "token", value = "Z" },
    }
}
```

### Non-token values

Replacing tokens with rules in the cases above doesn't add a lot of overhead.  
Instead of getting a token value like `{ type = "token", value = "..." }`, the value will be a node containing children to which the same rules were applied.  

```
a: X b W;
b: Y | Z;
```

```
{
    type = "rule",
    X = { type = "token", value = "X" },
    b = {
        type = "rule",
        alt = 1,
        Y = { type = "token", value = "Y" },
    },
    W = { type = "token", value = "W" },
}
```
