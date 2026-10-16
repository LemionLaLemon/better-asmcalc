# Better Assembly Calculator
a calculator again but this time it's better!!!!
Supports standard four functions (+ - * /), sqrt, and ^ and uses Pratt Parsing to evaluate the expression (for free order of operations!!!!)

<img width="292" height="329" alt="Demonstration of the calculator" src="https://github.com/user-attachments/assets/24669dd2-9f4a-4785-8434-fd45600136f1" />

https://youtu.be/MNfarZkCy8w

## Dependencies

| Library  | Purpose |
| ------------- | ------------- |
| LibX11  | Connections for making a window, inputs, drawing rectangles  |
| LibXft  | Text rendering  |
| C Lib | snprintf strod |
| C math | pow |

It's 1542 lines of beautiful handwritten x86 nasm assembly!!!!

Some issues are known already particularly with parenthesis (2) results in 0), will likely be fixed later, but for now you just have to type in expressions properly otherwise they might evaluate incorrectly.
Please do not submit issues for parsing issues.

## System Requirements

| Component | Minimum Requirements |
|---|---|
| **OS** | 64-bit Linux |
| **CPU** | x86-64 processor with SSE2 support (`addsd`, `subsd`, `mulsd`, `divsd`, `sqrtsd`) |
| **Memory** | m8, if you're running Linux, you meet the minimum RAM requirements already |
| **Display** | X11 or Wayland with XWayland |
| **Libraries** | `libX11`, `libXft`, `libc`, `libm` |
| **Fonts** | Cantarell (program would likely crash if not installed) |

System requirements are very strict because I can't compile it for windows duh
I am not willing to rewrite this to use Win32 API or Appkit for MacOS, that'd be a whole different project

