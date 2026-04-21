package Git;

use strict;
use warnings;
use Exporter 'import';
use Terminal;

our @EXPORT = qw(
    get_current_branch
    get_local_branches
    get_repo_root
    get_latest_version
    run_command
);

# ── Repository info ───────────────────────────────────────────────────────────

sub get_current_branch {
    my $branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`;
    chomp $branch;
    return $branch;
}

sub get_local_branches {
    my $raw = `git branch 2>/dev/null`;
    if ($? != 0 || !defined $raw || $raw eq '') {
        die "${FORMAT_RED}Error:${FORMAT_RESET} Could not list git branches. Are you inside a git repository?\n";
    }
    my @branches;
    for my $line (split /\n/, $raw) {
        $line =~ s/^\*?\s+//;
        $line =~ s/\s+$//;
        push @branches, $line if $line ne '';
    }
    die "${FORMAT_RED}Error:${FORMAT_RESET} No local branches found.\n" unless @branches;
    return @branches;
}

sub get_repo_root {
    my $root = `git rev-parse --show-toplevel 2>/dev/null`;
    chomp $root;
    die "${FORMAT_RED}Error:${FORMAT_RESET} Not inside a git repository.\n" unless $root;
    return $root;
}

# ── Tags ──────────────────────────────────────────────────────────────────────

sub get_latest_version {
    my @tags = grep { /^v\d+\.\d+$/ } split /\n/, `git tag --list 2>/dev/null`;
    return undef unless @tags;
    my @sorted = sort {
        my ($ax, $ay) = $a =~ /^v(\d+)\.(\d+)$/;
        my ($bx, $by) = $b =~ /^v(\d+)\.(\d+)$/;
        $ax <=> $bx || $ay <=> $by;
    } @tags;
    return $sorted[-1];
}

# ── Execution ─────────────────────────────────────────────────────────────────

sub run_command {
    my ($command) = @_;
    print "  ${FORMAT_YELLOW}\$ $command${FORMAT_RESET}\n";
    system($command);
    return $? == 0;
}

1;
