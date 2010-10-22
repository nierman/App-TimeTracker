package App::TimeTracker::Data::Task;
use 5.010;
use Moose;
use namespace::autoclean;
use App::TimeTracker;
use App::TimeTracker::Data::Project;
use DateTime::Format::ISO8601;
use DateTime::Format::Duration;

use MooseX::Storage;
with Storage('format' => 'JSON', 'io' => 'File');
MooseX::Storage::Engine->add_custom_type_handler(
    'DateTime' => (
        expand => sub { DateTime::Format::ISO8601->parse_datetime(shift) },
        collapse => sub { (shift)->iso8601 }
    )
);
my $dtf_dur = DateTime::Format::Duration->new(pattern => '%H:%M:%S');
my $dtf_sec = DateTime::Format::Duration->new(pattern => '%s');

has 'start' => (
    isa=>'DateTime',
    is=>'ro',
    required=>1,
    default=>sub { DateTime->now }
);
has 'stop' => (
    isa=>'DateTime',
    is=>'rw',
    trigger=>\&_calc_duration,
);
has 'seconds' => (
    isa=>'Int',
    is=>'rw',
);
has 'duration' => (
    isa=>'Str',
    is=>'rw',
);
has 'status' => (
    isa=>'Str',
    is=>'rw',
);
has 'user' => (
    isa=>'Str',
    is=>'ro',
    default=>'domm' # TODO: get user from config / system
);
has 'project' => (
    isa=>'App::TimeTracker::Data::Project',
    is=>'ro',
    required=>1,
);
has 'tags' => (
    isa=>'ArrayRef[App::TimeTracker::Data::Tag]',
    is=>'ro',
    default=>sub { [] }
);

sub _filepath {
    my $self = shift;
    my $start = $self->start;
    return ($start->year,sprintf('%02d',$start->month),$start->strftime("%Y%m%d-%H%M%S").'_'.$self->project->name.'.json');
}

sub _calc_duration {
    my ( $self, $stop ) = @_;
    my $delta = $self->stop - $self->start;
    $self->duration($dtf_dur->format_duration($delta));
    $self->seconds($dtf_sec->format_duration($delta));
}

sub storage_location {
    my ($self, $home) = @_;
    my $file = $home->file($self->_filepath);
    $file->parent->mkpath;
    return $file;
}

sub save {
    my ($self, $home) = @_;

    my $file = $self->storage_location($home)->stringify;
    $self->store($file);
    return $file;
}

sub current {
    my ($class, $home) = @_;
    my $current_file = $home->file('current');
    return unless -e $current_file;
    return $class->load($current_file->slurp(chomp=>1));
}

sub say_project_tags {
    my $self = shift;
    return $self->project->name . ' (TODO tags)';
}

__PACKAGE__->meta->make_immutable;
1;

__END__

