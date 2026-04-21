package Terminal;

use strict;
use warnings;
use POSIX qw();
use Exporter 'import';

our @EXPORT = qw(
    enable_raw_mode restore_terminal
    hide_cursor show_cursor move_up clear_line
    interactive_select
    prompt_text
    $FORMAT_RESET
    $FORMAT_BOLD
    $FORMAT_DIM
    $FORMAT_REVERSE
    $FORMAT_RED
    $FORMAT_GREEN
    $FORMAT_YELLOW
    $FORMAT_CYAN
    $FORMAT_WHITE
    $FORMAT_BG_RED
);

# ── Formatting ────────────────────────────────────────────────────────────────

our $FORMAT_RESET   = "\e[0m";

our $FORMAT_BOLD    = "\e[1m";
our $FORMAT_DIM     = "\e[2m";
our $FORMAT_REVERSE = "\e[7m";

our $FORMAT_RED     = "\e[31m";
our $FORMAT_GREEN   = "\e[32m";
our $FORMAT_YELLOW  = "\e[33m";
our $FORMAT_CYAN    = "\e[36m";
our $FORMAT_WHITE   = "\e[37m";

our $FORMAT_BG_RED  = "\e[41m";

# ── Terminal control ──────────────────────────────────────────────────────────

my $original_termios;

sub enable_raw_mode {
    $original_termios = POSIX::Termios->new;
    $original_termios->getattr(0);

    my $raw = POSIX::Termios->new;
    $raw->getattr(0);
    $raw->setlflag(
        $raw->getlflag & ~(POSIX::ECHO | POSIX::ICANON)
    );
    $raw->setcc(POSIX::VMIN,  1);
    $raw->setcc(POSIX::VTIME, 0);
    $raw->setattr(0, POSIX::TCSANOW);
}

sub restore_terminal {
    $original_termios->setattr(0, POSIX::TCSANOW) if defined $original_termios;
}

END { restore_terminal(); show_cursor() }

# ── ANSI helpers ──────────────────────────────────────────────────────────────

sub hide_cursor { print "\e[?25l" }
sub show_cursor { print "\e[?25h" }
sub move_up     { my ($n) = @_; print "\e[${n}A" if $n > 0 }
sub clear_line  { print "\e[2K\r" }

# ── Interactive selector ──────────────────────────────────────────────────────
#
# interactive_select($prompt, \@options, %args) → selected index
#
# Optional named args:
#   default => $i          initially highlighted index (default 0)
#   exclude => $label      label that is dimmed and unselectable
#   mark    => $label      label to annotate with a trailing " *"

sub interactive_select {
    my ($prompt, $options_ref, %args) = @_;
    my @options       = @$options_ref;
    my $n             = scalar @options;
    my $selected      = $args{default} // 0;
    my $exclude_value = $args{exclude};
    my $mark_value    = $args{mark};

    hide_cursor();
    enable_raw_mode();

    print "${FORMAT_BOLD}$prompt${FORMAT_RESET}\n";

    my $render = sub {
        for my $i (0 .. $n - 1) {
            clear_line();
            my $label       = $options[$i];
            my $is_excluded = defined $exclude_value && $label eq $exclude_value;
            my $suffix      = (defined $mark_value && $label eq $mark_value) ? ' *' : '';

            if ($i == $selected) {
                if ($is_excluded) {
                    print "  ${FORMAT_BG_RED}${FORMAT_WHITE}> $label$suffix (already selected above) ${FORMAT_RESET}\n";
                } else {
                    print "  ${FORMAT_REVERSE}> $label$suffix ${FORMAT_RESET}\n";
                }
            } else {
                if ($is_excluded) {
                    print "  ${FORMAT_DIM}  $label$suffix${FORMAT_RESET}\n";
                } else {
                    print "    $label$suffix\n";
                }
            }
        }
    };

    $render->();

    while (1) {
        my $ch = '';
        sysread(STDIN, $ch, 1);

        if ($ch eq "\e") {
            my $seq = '';
            sysread(STDIN, $seq, 2);
            if    ($seq eq '[A') { $selected = ($selected - 1 + $n) % $n }
            elsif ($seq eq '[B') { $selected = ($selected + 1)      % $n }
        } elsif ($ch eq "\n" || $ch eq "\r") {
            if (defined $exclude_value && $options[$selected] eq $exclude_value) {
                move_up($n);
                $render->();
                next;
            }
            last;
        }

        move_up($n);
        $render->();
    }

    restore_terminal();
    show_cursor();

    # Collapse menu to a single summary line
    move_up($n + 1);
    for my $i (0 .. $n) { clear_line(); print "\n" }
    move_up($n + 1);
    clear_line();
    print "${FORMAT_BOLD}$prompt${FORMAT_RESET} ${FORMAT_GREEN}$options[$selected]${FORMAT_RESET}\n";

    return $selected;
}

# ── Text prompt ───────────────────────────────────────────────────────────────
#
# prompt_text($prompt, \@chunks, %args) → entered string
#
# \@chunks: pre-populated segments shown at the prompt. Backspace removes one
#   typed character at a time; when the typed buffer is empty, each backspace
#   removes the rightmost chunk entirely.
#
# Optional named args:
#   hint       => $str   dim text shown after the prompt on the same line
#   empty_text => $str   dim text used in the summary line when result is empty

sub prompt_text {
    my ($prompt, $chunks_ref, %args) = @_;
    my @chunks     = defined $chunks_ref ? @$chunks_ref : ();
    my $hint       = $args{hint};
    my $empty_text = $args{empty_text};

    enable_raw_mode();
    show_cursor();

    if (defined $hint) {
        print "${FORMAT_BOLD}$prompt${FORMAT_RESET} ${FORMAT_DIM}$hint${FORMAT_RESET}\n";
    } else {
        print "${FORMAT_BOLD}$prompt${FORMAT_RESET}\n";
    }
    print "> " . join('', @chunks);

    my $typed = '';

    while (1) {
        my $ch = '';
        sysread(STDIN, $ch, 1);

        if ($ch eq "\n" || $ch eq "\r") {
            print "\n";
            last;
        } elsif ($ch eq "\e") {         # ESC — start of an escape sequence (e.g. arrow keys); read and discard the next 2 bytes
            my $seq = '';
            sysread(STDIN, $seq, 2);
        } elsif ($ch eq "\x7f" || $ch eq "\x08") {  # \x7f = DEL (backspace on most terminals); \x08 = BS (some terminals/keyboards)
            if (length($typed) > 0) {
                chop $typed;
                print "\b \b";          # \b moves the cursor left one position; space overwrites the character; \b moves left again
            } elsif (@chunks) {
                pop @chunks;
                clear_line();
                print "> " . join('', @chunks);
            }
        } elsif ($ch ge ' ') {
            $typed .= $ch;
            print $ch;
        }
    }

    restore_terminal();

    my $result = join('', @chunks) . $typed;
    $result =~ s/^\s+|\s+$//g;

    # Collapse to a single summary line
    move_up(2);
    clear_line();
    if ($result eq '' && defined $empty_text) {
        print "${FORMAT_BOLD}$prompt${FORMAT_RESET} ${FORMAT_DIM}$empty_text${FORMAT_RESET}\n";
    } else {
        print "${FORMAT_BOLD}$prompt${FORMAT_RESET} ${FORMAT_GREEN}$result${FORMAT_RESET}\n";
    }

    return $result;
}

1;
