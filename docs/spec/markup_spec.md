The markup language is inspired by Lisp like languages:

```lisp
(t # Title
    This is a title, anything can be put here. If you want a subelement, you can just put a \( in it: 
    (b This is bold)(br)
)

(p # Paragraph
Newlines are ignored by default:
)

(p
    Comments start with a \# and end with the next newline: # This is a comment and will not be rendered
)

(p
    Multiline Comments start with \#\( and end with \)\#. Example: #( This is an example comment )#
)

(component 
    ("test")    #( This is a parameter, a parameter is defined within parentheses and begins with a value instead of an identifier.
                Also, this declares a component with the name "test". A component contains blocks that will be inserted where it is called, and a component can be passed
                parameters. More about these later.
                )#
    This is an example component
)

(test)

(component
    ("parameters")
    ("title" 'string) # This defines a parameter for the component "parameters" called "title" with a type of 'string, a ' followed by an identifier, indicates a type
    Title is $title # This will insert the value of title into this string
)

(parameters ("title" "Hello World"))
```
