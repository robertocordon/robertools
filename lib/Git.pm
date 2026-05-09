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
    branchHasRemote
    git_checkout
    git_create_branch
    git_merge
    git_delete_branch
    git_add
    git_commit
    git_tag
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
    my @tags = grep { /^v\d+(?:\.\d+)+$/ } split /\n/, `git tag --list 2>/dev/null`;
    return undef unless @tags;
    my @sorted = sort {
        my @ap = ($a =~ /(\d+)/g);
        my @bp = ($b =~ /(\d+)/g);
        my $len = @ap > @bp ? scalar @ap : scalar @bp;
        for my $i (0 .. $len - 1) {
            my $cmp = ($ap[$i] // 0) <=> ($bp[$i] // 0);
            return $cmp if $cmp;
        }
        return 0;
    } @tags;
    return $sorted[-1];
}

# ── Remote ───────────────────────────────────────────────────────────────────

sub branchHasRemote {
    my ($branch) = @_;
    my $result = `git branch -r --list "origin/$branch" 2>/dev/null`;
    chomp $result;
    return $result ne '';
}

# ── Git commands ─────────────────────────────────────────────────────────────

sub run_command {
    my ($command) = @_;
    print "  ${FORMAT_YELLOW}\$ $command${FORMAT_RESET}\n";
    system($command);
    return $? == 0;
}

sub git_checkout      { run_command("git checkout $_[0]") }
sub git_create_branch { run_command("git checkout -b $_[0]") }
sub git_delete_branch { run_command("git branch -d $_[0]") }
sub git_add           { run_command("git add '$_[0]'") }
sub git_tag           { run_command("git tag $_[0]") }

sub git_commit {
    my ($message) = @_;
    (my $safe = $message) =~ s/'/'\\''/g;
    run_command("git commit -m '$safe'");
}

sub git_merge {
    my ($branch, %opts) = @_;
    my $flags = $opts{edit} ? '--no-ff' : '--no-ff --no-edit';
    my $ok = run_command("git merge $flags $branch");
    if ($ok && $opts{push}) {
        my $current = get_current_branch();
        return $ok unless branchHasRemote($current);
        print "  ${FORMAT_YELLOW}\$ git push${FORMAT_RESET}\n";
        my $push_output = `git push 2>&1`;
        if ($? != 0) {
            chomp(my $err = $push_output);
            my $msg = $err ? ": $err" : '';
            print "${FORMAT_RED}Could not push $current$msg${FORMAT_RESET}\n";
        } else {
            print $push_output if $push_output;
        }
    }
    return $ok;
}

1;
