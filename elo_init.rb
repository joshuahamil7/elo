#!/usr/bin/env ruby
# elo_init.rb - Simplified Elo Physics/Math RPN System
# author: joshuahamil7

module EloSystem
  def self.install!
    puts "Installing Elo Physics/Math RPN Language..."
    puts "=" * 80
    
    # Create directory structure
    require 'fileutils'
    FileUtils.mkdir_p('elo')
    FileUtils.mkdir_p('elo/lib')
    FileUtils.mkdir_p('elo/examples')
    
    write_files
    
    puts "\n✓ Installation complete!"
    puts "\nFiles created in 'elo/' directory:"
    Dir.glob('elo/**/*').select { |f| File.file?(f) }.each do |f|
      puts "  #{f}"
    end
    
    puts "\nUsage:"
    puts "  ruby elo/elo.rb              # Start REPL"
    puts "  ruby elo/elo.rb -e '5 3 +'   # Evaluate expression"
    puts "\nTry: ruby elo/elo.rb"
    puts "Then type: 5 3 +"
  end
  
  def self.write_files
    # Main executable
    File.write('elo/elo.rb', ELO_MAIN)
    File.chmod(0755, 'elo/elo.rb')
    
    # Core library files
    File.write('elo/lib/elo_core.rb', ELO_CORE)
    File.write('elo/lib/elo_lexer.rb', ELO_LEXER)
    File.write('elo/lib/elo_interpreter.rb', ELO_INTERPRETER)
    File.write('elo/lib/elo_repl.rb', ELO_REPL)
    
    # Example files
    File.write('elo/examples/basic.elo', BASIC_EXAMPLE)
    File.write('elo/examples/physics.elo', PHYSICS_EXAMPLE)
  end
  
  ELO_MAIN = <<~'RUBY'
#!/usr/bin/env ruby
# elo.rb - Elo Physics/Math RPN Language

require_relative 'lib/elo_core'
require_relative 'lib/elo_repl'

if ARGV.empty?
  EloREPL.new.run
elsif ARGV.include?('--help') || ARGV.include?('-h')
  puts "Elo Physics/Math RPN Language v1.0"
  puts "Usage:"
  puts "  ruby elo.rb              # Start REPL"
  puts "  ruby elo.rb -e 'expr'    # Evaluate expression"
  puts "  ruby elo.rb --help       # Show this help"
elsif ARGV.include?('-e')
  expr_idx = ARGV.index('-e')
  code = ARGV[expr_idx + 1]
  EloInterpreter.new.evaluate(code)
else
  puts "Unknown option. Use --help for usage."
end
RUBY
  
  ELO_CORE = <<~'RUBY'
# lib/elo_core.rb - Core Elo system
require_relative 'elo_lexer'
require_relative 'elo_interpreter'
ELO_SCALE = 1_000  # For 3 decimal places precision
RUBY
  
  ELO_LEXER = <<~'RUBY'
# lib/elo_lexer.rb - Simple tokenizer
class EloLexer
  def initialize(source)
    @source = source
  end
  
  def tokenize
    tokens = []
    @source.scan(/\d+(?:\.\d+)?|[+\-*\/^()]|sin|cos|tan|sqrt|print|pi|e|[a-zA-Z_]+/) do |match|
      case match
      when /\d+(?:\.\d+)?/
        tokens << {type: :number, value: match.to_f}
      when '+', '-', '*', '/', '^'
        tokens << {type: :operator, value: match}
      when 'sin', 'cos', 'tan', 'sqrt'
        tokens << {type: :function, value: match}
      when 'print'
        tokens << {type: :keyword, value: match}
      when 'pi'
        tokens << {type: :constant, value: Math::PI}
      when 'e'
        tokens << {type: :constant, value: Math::E}
      else
        tokens << {type: :identifier, value: match}
      end
    end
    tokens
  end
end
RUBY
  
  ELO_INTERPRETER = <<~'RUBY'
# lib/elo_interpreter.rb - Stack-based interpreter
class EloInterpreter
  def initialize(debug: false)
    @debug = debug
    @stack = []
    @constants = {
      'pi' => Math::PI,
      'e' => Math::E,
      'c' => 299792458,      # Speed of light
      'g' => 9.80665,        # Gravity
      'G' => 6.67430e-11     # Gravitational constant
    }
  end
  
  def evaluate(code)
    tokens = EloLexer.new(code).tokenize
    
    if @debug
      puts "Tokens:"
      tokens.each { |t| puts "  #{t[:type]}: #{t[:value]}" }
    end
    
    tokens.each do |token|
      case token[:type]
      when :number
        @stack.push(token[:value])
      when :constant
        @stack.push(token[:value])
      when :operator
        handle_operator(token[:value])
      when :function
        handle_function(token[:value])
      when :keyword
        handle_keyword(token[:value])
      when :identifier
        if @constants.key?(token[:value].downcase)
          @stack.push(@constants[token[:value].downcase])
        else
          puts "Warning: Unknown identifier '#{token[:value]}'"
        end
      end
      
      puts "Stack: #{@stack}" if @debug
    end
    
    result = @stack.last
    @stack.clear
    result
  end
  
  private
  
  def handle_operator(op)
    return if @stack.size < 2
    
    b = @stack.pop
    a = @stack.pop
    
    result = case op
             when '+' then a + b
             when '-' then a - b
             when '*' then a * b
             when '/' then a / b
             when '^' then a ** b
             end
    
    @stack.push(result)
  end
  
  def handle_function(func)
    return if @stack.empty?
    
    value = @stack.pop
    result = case func
             when 'sin' then Math.sin(value)
             when 'cos' then Math.cos(value)
             when 'tan' then Math.tan(value)
             when 'sqrt' then Math.sqrt(value)
             end
    
    @stack.push(result)
  end
  
  def handle_keyword(keyword)
    case keyword
    when 'print'
      value = @stack.pop
      puts value
      @stack.push(value)  # Keep value on stack
    end
  end
end
RUBY
  
  ELO_REPL = <<~'RUBY'
# lib/elo_repl.rb - Simple REPL
require 'readline'

class EloREPL
  PROMPT = "elo> "
  
  def initialize
    @interpreter = EloInterpreter.new
    @history_file = File.expand_path('~/.elo_history')
    load_history
  end
  
  def run
    show_welcome
    
    loop do
      begin
        line = Readline.readline(PROMPT, true)
        
        break if line.nil? || line.strip.downcase == 'quit'
        
        handle_input(line.strip)
        
      rescue Interrupt
        puts "\nUse 'quit' to exit"
      rescue => e
        puts "Error: #{e.message}"
      end
    end
    
    puts "\nGoodbye!"
  end
  
  private
  
  def show_welcome
    puts "=" * 80
    puts "Elo Physics/Math RPN Language REPL"
    puts "=" * 80
    puts "Type expressions in RPN (Reverse Polish Notation)"
    puts "Examples:"
    puts "  5 3 +        # 5 + 3 = 8"
    puts "  2 3 *        # 2 * 3 = 6"
    puts "  pi sin       # sin(π) = 0"
    puts "  g print      # print gravity constant"
    puts "  quit         # Exit"
    puts ""
  end
  
  def handle_input(line)
    return if line.empty?
    
    save_to_history(line)
    
    if line.downcase == 'help'
      show_help
      return
    end
    
    begin
      result = @interpreter.evaluate(line)
      if result
        puts "=> #{result}"
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end
  
  def show_help
    puts <<~HELP
    Elo RPN Language Help:
    
    RPN Syntax:
      5 3 +           # 5 + 3 = 8
      5 3 2 * +       # 5 + (3 * 2) = 11
    
    Operators:
      + - * / ^
    
    Functions:
      sin, cos, tan, sqrt
    
    Constants:
      pi, e, c (speed of light), g (gravity), G (gravitational constant)
    
    Keywords:
      print - Print top of stack
    
    Examples:
      5 3 + print     # Print 8
      pi 2 / cos      # cos(π/2) = 0
      16 sqrt         # √16 = 4
    HELP
  end
  
  def load_history
    if File.exist?(@history_file)
      File.readlines(@history_file).each do |line|
        Readline::HISTORY << line.chomp
      end
    end
  end
  
  def save_to_history(line)
    return if line.strip.empty?
    
    Readline::HISTORY << line
    
    begin
      File.open(@history_file, 'a') { |f| f.puts(line) }
    rescue
      # Ignore write errors
    end
  end
end
RUBY
  
  BASIC_EXAMPLE = <<~ELO
# Basic Elo examples

# Arithmetic
5 3 + print
5 3 - print
5 3 * print
6 3 / print
2 3 ^ print

# Math functions
pi print
pi 2 / sin print
pi cos print
16 sqrt print

# Stack operations
5 dup * print

# Constants
g print
c print
G print
ELO
  
  PHYSICS_EXAMPLE = <<~ELO
# Physics examples

# Newton's Second Law: F = m*a
5 9.8 * print

# Gravitational force: F = G*m1*m2/r^2
# Earth (5.972e24 kg) and 1000kg object at Earth's surface (6.371e6 m)
G 5.972e24 * 1000 * 6.371e6 2 ^ / print

# Kinetic energy: KE = 0.5 * m * v^2
1500 25 2 ^ * 0.5 * print

# Speed of light operations
c print
c 1000 / print
ELO
end

# Run installation
if __FILE__ == $0
  EloSystem.install!
end
