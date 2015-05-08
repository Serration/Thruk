package Mojolicious::Plugin::Thruk::ToolkitRenderer;

# based on  Mojolicious::Plugin::ToolkitRenderer

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Carp qw/confess/;
use Template ();

=head1 METHODS

=head2 register

    register this renderer

=cut
sub register {
    my($self, $app, $settings) = @_;

    $app->{'tt'} = Template->new($settings->{'config'});
    $app->renderer->add_handler( 'tt' => \&render_tt);

    $app->helper(
        'render_tt' => sub {
            shift->render( 'handler' => 'tt', @_ );
        }
    );

    return;
}

=head2 render_tt

    do the rendering

=cut
sub render_tt {
    #my($renderer, $controller, $output, $options) = @_;
    my $template = $_[1]->app->{'tt'};
    if(!$_[1]->stash->{'_template'}) {
        $_[1]->app->renderer->default_handler('ep');
        confess("no _template set!");
    }

    if($_[1]->stash->{'additional_template_paths'}) {
        $template->context->{'LOAD_TEMPLATES'}->[0]->{'INCLUDE_PATH'} =
            [ @{$_[1]->stash->{'additional_template_paths'}},
                $_[1]->config->{'View::TT'}->{'INCLUDE_PATH'}
            ];
    }

# TODO: remove
for my $forbidden (qw/action app cb controller data extends format handler json layout namespace path status template text variant/) {
    delete $_[1]->stash->{$forbidden};
}
    $template->process(
        $_[1]->stash->{'_template'},
        $_[1]->stash,
        $_[2],
    ) || do {
        my $err = $template->error.' on '.$_[1]->stash->{'_template'};
        $_[1]->log->error($err);
        $_[1]->error($err);
        if($_[1]->{'errored'}) {
            # error happenend on the error page itself
            $_[1]->app->renderer->default_handler('ep');
            confess($err);
        } else {
            return($_[1]->detach("/error/index/13"));
        }
    };
    return $_[2];
}

1;
__END__

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin(
        'ToolkitRenderer',
        {
            config => {
                RELATIVE  => 1,
                EVAL_PERL => 0,
                FILTERS   => { ucfirst => sub { return ucfirst shift } },
                ENCODING  => 'utf8',
            },
        },
    );
    $self->renderer->default_handler('tt');

=head1 DESCRIPTION

This module is a Mojolicious plugin for easy use of L<Template> Toolkit. It
adds a "tt" handler and provides a "render_tt" helper method.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<Template>, L<Mojolicious::Plugin::ToolkitRenderer>.

=cut
