# elo
elo is a math physics repl using RPN — HP

## REPL
help         # Show help
quit         # Exit REPL

5 3 +        # 5 + 3 = 8
5 3 2 * +    # 5 + (3 * 2) = 11


## Quick Setup & Install
cd ~/projects
curl -s https://raw.githubusercontent.com/joshuahamil7/elo/main/elo_init.rb | ruby

## Examples

### Simple math
pi 2 / cos        # cos(π/2) = 0
16 sqrt           # √16 = 4

### Physics
5 9.8 *           # F = m*a (5kg * g)
c print           # Speed of light

### Constants
pi         # 3.14159
e          # 2.71828
c          # 299792458 (speed of light)
g          # 9.80665 (gravity)
G          # 6.67430e-11 (gravitational constant)
