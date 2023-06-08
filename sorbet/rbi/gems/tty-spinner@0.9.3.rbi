# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `tty-spinner` gem.
# Please instead update this file by running `bin/tapioca gem tty-spinner`.

# source://tty-spinner//lib/tty/spinner/version.rb#3
module TTY; end

# source://tty-spinner//lib/tty/spinner/formats.rb#4
module TTY::Formats; end

# source://tty-spinner//lib/tty/spinner/formats.rb#5
TTY::Formats::FORMATS = T.let(T.unsafe(nil), Hash)

# Used for creating terminal spinner
#
# @api public
#
# source://tty-spinner//lib/tty/spinner/version.rb#4
class TTY::Spinner
  include ::TTY::Formats
  include ::MonitorMixin

  # Initialize a spinner
  #
  # @api public
  # @example
  #   spinner = TTY::Spinner.new
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @param message [String] the message to print in front of the spinner
  # @param options [Hash]
  # @return [Spinner] a new instance of Spinner
  #
  # source://tty-spinner//lib/tty/spinner.rb#94
  def initialize(*args); end

  # Notifies the TTY::Spinner that it is running under a multispinner
  #
  # @api private
  # @param the [TTY::Spinner::Multi] multispinner that it is running under
  #
  # source://tty-spinner//lib/tty/spinner.rb#140
  def attach_to(multispinner); end

  # Start automatic spinning animation
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#240
  def auto_spin; end

  # Clear current line
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#460
  def clear_line; end

  # Whether the spinner has completed spinning
  #
  # @api public
  # @return [Boolean] whether or not the spinner has finished
  #
  # source://tty-spinner//lib/tty/spinner.rb#149
  def done?; end

  # Duration of the spinning animation
  #
  # @api public
  # @return [Numeric]
  #
  # source://tty-spinner//lib/tty/spinner.rb#319
  def duration; end

  # Finish spinning and set state to :error
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#447
  def error(stop_message = T.unsafe(nil)); end

  # Whether the spinner is in the error state. This is only true
  # temporarily while it is being marked with a failure mark.
  #
  # @api public
  # @return [Boolean] whether or not the spinner is erroring
  #
  # source://tty-spinner//lib/tty/spinner.rb#178
  def error?; end

  # Execute this spinner job
  #
  # @api public
  # @yield [TTY::Spinner]
  #
  # source://tty-spinner//lib/tty/spinner.rb#224
  def execute_job; end

  # The current format type
  #
  # @api public
  # @return [String]
  #
  # source://tty-spinner//lib/tty/spinner.rb#38
  def format; end

  # Whether to show or hide cursor
  #
  # @api public
  # @return [Boolean]
  #
  # source://tty-spinner//lib/tty/spinner.rb#45
  def hide_cursor; end

  # The amount of time between frames in auto spinning
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#66
  def interval; end

  # Add job to this spinner
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#209
  def job(&work); end

  # Check if this spinner has a scheduled job
  #
  # @api public
  # @return [Boolean]
  #
  # source://tty-spinner//lib/tty/spinner.rb#233
  def job?; end

  # Join running spinner
  #
  # @api public
  # @param timeout [Float] the timeout for join
  #
  # source://tty-spinner//lib/tty/spinner.rb#329
  def join(timeout = T.unsafe(nil)); end

  # Kill running spinner
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#340
  def kill; end

  # The message to print before the spinner
  #
  # @api public
  # @return [String] the current message
  #
  # source://tty-spinner//lib/tty/spinner.rb#53
  def message; end

  # Retrieve next character
  #
  # @api private
  # @return [String]
  #
  # source://tty-spinner//lib/tty/spinner.rb#421
  def next_char; end

  # Register callback
  #
  # @api public
  # @param name [Symbol] the name for the event to listen for, e.i. :complete
  # @return [self]
  #
  # source://tty-spinner//lib/tty/spinner.rb#190
  def on(name, &block); end

  # The object that responds to print call defaulting to stderr
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#31
  def output; end

  # Pause spinner automatic animation
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#276
  def pause; end

  # Checked if current spinner is paused
  #
  # @api public
  # @return [Boolean]
  #
  # source://tty-spinner//lib/tty/spinner.rb#269
  def paused?; end

  # Redraw the indent for this spinner, if it exists
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner.rb#373
  def redraw_indent; end

  # Reset the spinner to initial frame
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#125
  def reset; end

  # Resume spinner automatic animation
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#287
  def resume; end

  # The current row inside the multi spinner
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#71
  def row; end

  # Run spinner while executing job
  #
  # @api public
  # @example
  #   spinner.run('Migrated DB') { ... }
  # @param stop_message [String] the message displayed when block is finished
  # @yield automatically animate and finish spinner
  #
  # source://tty-spinner//lib/tty/spinner.rb#304
  def run(stop_message = T.unsafe(nil), &block); end

  # Perform a spin
  #
  # @api public
  # @return [String] the printed data
  #
  # source://tty-spinner//lib/tty/spinner.rb#352
  def spin; end

  # Whether the spinner is spinning
  #
  # @api public
  # @return [Boolean] whether or not the spinner is spinning
  #
  # source://tty-spinner//lib/tty/spinner.rb#158
  def spinning?; end

  # Start timer and unlock spinner
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#200
  def start; end

  # Finish spining
  #
  # @api public
  # @param stop_message [String] the stop message to print
  #
  # source://tty-spinner//lib/tty/spinner.rb#387
  def stop(stop_message = T.unsafe(nil)); end

  # Finish spinning and set state to :success
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner.rb#434
  def success(stop_message = T.unsafe(nil)); end

  # Whether the spinner is in the success state.
  # When true the spinner is marked with a success mark.
  #
  # @api public
  # @return [Boolean] whether or not the spinner succeeded
  #
  # source://tty-spinner//lib/tty/spinner.rb#168
  def success?; end

  # Tokens for the message
  #
  # @api public
  # @return [Hash[Symbol, Object]] the current tokens
  #
  # source://tty-spinner//lib/tty/spinner.rb#61
  def tokens; end

  # Update string formatting tokens
  #
  # @api public
  # @param tokens [Hash[Symbol]] the tokens used in formatting string
  #
  # source://tty-spinner//lib/tty/spinner.rb#470
  def update(tokens); end

  private

  # Emit callback
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner.rb#533
  def emit(name, *args); end

  # Execute a block on the proper terminal line if the spinner is running
  # under a multispinner. Otherwise, execute the block on the current line.
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner.rb#483
  def execute_on_line; end

  # Find frames by token name
  #
  # @api private
  # @param token [Symbol] the name for the frames
  # @return [Array, String]
  #
  # source://tty-spinner//lib/tty/spinner.rb#547
  def fetch_format(token, property); end

  # Replace any token inside string
  #
  # @api private
  # @param string [String] the string containing tokens
  # @return [String]
  #
  # source://tty-spinner//lib/tty/spinner.rb#563
  def replace_tokens(string); end

  # Check if IO is attached to a terminal
  #
  # return [Boolean]
  #
  # @api public
  # @return [Boolean]
  #
  # source://tty-spinner//lib/tty/spinner.rb#526
  def tty?; end

  # Write data out to output
  #
  # @api private
  # @return [nil]
  #
  # source://tty-spinner//lib/tty/spinner.rb#509
  def write(data, clear_first = T.unsafe(nil)); end
end

# @api public
#
# source://tty-spinner//lib/tty/spinner.rb#24
TTY::Spinner::CROSS = T.let(T.unsafe(nil), String)

# @api public
#
# source://tty-spinner//lib/tty/spinner.rb#26
TTY::Spinner::CURSOR_LOCK = T.let(T.unsafe(nil), Monitor)

# @api public
#
# source://tty-spinner//lib/tty/spinner.rb#20
TTY::Spinner::ECMA_CSI = T.let(T.unsafe(nil), String)

# @api public
#
# source://tty-spinner//lib/tty/spinner.rb#22
TTY::Spinner::MATCHER = T.let(T.unsafe(nil), Regexp)

# Used for managing multiple terminal spinners
#
# @api public
#
# source://tty-spinner//lib/tty/spinner/multi.rb#13
class TTY::Spinner::Multi
  include ::Enumerable
  include ::MonitorMixin
  extend ::Forwardable

  # Initialize a multispinner
  #
  # @api public
  # @example
  #   spinner = TTY::Spinner::Multi.new
  # @option options
  # @option options
  # @option options
  # @option options
  # @option options
  # @param message [String] the optional message to print in front of the top level spinner
  # @param options [Hash]
  # @return [Multi] a new instance of Multi
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#54
  def initialize(*args); end

  # Auto spin the top level spinner & all child spinners
  # that have scheduled jobs
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#143
  def auto_spin; end

  # Create a spinner instance
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#104
  def create_spinner(pattern_or_spinner, options); end

  # Check if all spinners are done
  #
  # @api public
  # @return [Boolean]
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#208
  def done?; end

  # source://forwardable/1.3.1/forwardable.rb#226
  def each(*args, &block); end

  # source://forwardable/1.3.1/forwardable.rb#226
  def empty?(*args, &block); end

  # Stop all spinners with error status
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#253
  def error; end

  # Check if any spinner errored
  #
  # @api public
  # @return [Boolean]
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#230
  def error?; end

  # source://forwardable/1.3.1/forwardable.rb#226
  def length(*args, &block); end

  # Find the number of characters to move into the line
  # before printing the spinner
  #
  # @api public
  # @param line_no [Integer] the current spinner line number for which line inset is calculated
  # @return [String] the inset
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#191
  def line_inset(line_no); end

  # Increase a row count
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#122
  def next_row; end

  # Listen on event
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#260
  def on(key, &callback); end

  # Pause all spinners
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#170
  def pause; end

  # Register a new spinner
  #
  # @api public
  # @param pattern_or_spinner [String, TTY::Spinner] the pattern used for creating spinner, or a spinner instance
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#82
  def register(pattern_or_spinner, **options, &job); end

  # Resume all spinners
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#177
  def resume; end

  # The current count of all rendered rows
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#30
  def rows; end

  # Perform a single spin animation
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#159
  def spin; end

  # Stop all spinners
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#239
  def stop; end

  # Stop all spinners with success status
  #
  # @api public
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#246
  def success; end

  # Check if all spinners succeeded
  #
  # @api public
  # @return [Boolean]
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#219
  def success?; end

  # Get the top level spinner if it exists
  #
  # @api public
  # @return [TTY::Spinner] the top level spinner
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#133
  def top_spinner; end

  private

  # Handle the done state
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#343
  def done_handler; end

  # Fire an event
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#287
  def emit(key, *args); end

  # Handle the error state
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#331
  def error_handler; end

  # Observe spinner for events to notify top spinner of current state
  #
  # @api private
  # @param spinner [TTY::Spinner] the spinner to listen to for events
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#299
  def observe(spinner); end

  # Handle spin event
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#309
  def spin_handler; end

  # Handle the success state
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#319
  def success_handler; end

  # Check if this spinner should revolve to keep constant speed
  # matching top spinner interval
  #
  # @api private
  #
  # source://tty-spinner//lib/tty/spinner/multi.rb#275
  def throttle; end
end

# @api public
#
# source://tty-spinner//lib/tty/spinner/multi.rb#21
TTY::Spinner::Multi::DEFAULT_INSET = T.let(T.unsafe(nil), Hash)

# @api public
#
# source://tty-spinner//lib/tty/spinner.rb#18
class TTY::Spinner::NotSpinningError < ::StandardError; end

# @api public
#
# source://tty-spinner//lib/tty/spinner.rb#23
TTY::Spinner::TICK = T.let(T.unsafe(nil), String)

# @api public
#
# source://tty-spinner//lib/tty/spinner/version.rb#5
TTY::Spinner::VERSION = T.let(T.unsafe(nil), String)