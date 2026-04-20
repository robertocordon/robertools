package Terminal;

use strict;
use warnings;
use POSIX qw();
use Exporter 'import';

our @EXPORT = qw(
    enable_raw_mode restore_terminal
    hide_cursor show_cursor move_up clear_line
    interactive_select
);

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

END { restore_terminal() }

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

    print "\e[1m$prompt\e[0m\n";

    my $render = sub {
        for my $i (0 .. $n - 1) {
            clear_line();
            my $label       = $options[$i];
            my $is_excluded = defined $exclude_value && $label eq $exclude_value;
            my $suffix      = (defined $mark_value && $label eq $mark_value) ? ' *' : '';

            if ($i == $selected) {
                if ($is_excluded) {
                    print "  \e[41m\e[37m> $label$suffix (already selected above) \e[0m\n";
                } else {
                    print "  \e[7m> $label$suffix \e[0m\n";
                }
            } else {
                if ($is_excluded) {
                    print "  \e[2m  $label$suffix\e[0m\n";
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
    print "\e[1m$prompt\e[0m \e[32m$options[$selected]\e[0m\n";

    return $selected;
}

1;
