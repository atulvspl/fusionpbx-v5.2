use Net::WebSocket::Server;
use Net::AMQP::RabbitMQ;
require "/usr/local/pbx/bin/default.include.pl";

use LWP::Simple;

%sms_connections = ();
my $mq = Net::AMQP::RabbitMQ->new();
$mq->connect("localhost", { user => "guest", password => "guest" });
$mq->channel_open(1);
$mq->queue_declare(1, "incoming");

%incoming_connection = ();

Net::WebSocket::Server->new(
	listen => 8088,

	on_connect => sub {
		my ($serv, $conn) = @_;
		warn "Get connection from " . $conn->ip() . "\n";
		$conn->on(
			utf8 => sub {
				my ($conn, $msg) = @_;
				warn "Get MSG: $msg";

				$conn->send_utf8($msg);
				%hash = &Json2Hash($msg);
				$action = $hash{action} || '';
				unless ($hash{action} && $hash{agent} && $hash{domain_name}) {
					warn "Reply failed action!\n";
					$conn->send_utf8(&Hash2Json('status' => 0, 'message' => 'unknown msg'));
					return;
				}

				%result = ();
				if ($action eq 'login') {
					$uuid = &genuuid();
					$old_uuid = &check_connection($conn);
					if ($old_uuid) {
						delete $incoming_connections{$old_uuid};
					}

					$incoming_connections{$uuid}{conn} = $conn;
					$incoming_connections{$uuid}{agent} = $hash{agent};
					$incoming_connections{$uuid}{domain_name} = $hash{domain_name};
					$result{status} = '1';

					$result{message} = "$action  ok!";


				}
				$str = &Hash2Json(%result);
				warn "Reply: $str";
				$conn->send_utf8($str);
			},
			disconnect => sub {
				local ($connection, $code, $reason) = @_;
				$uuid = &check_connection($connection);
				if ($uuid) {
					delete $incoming_connections{$uuid};
				}

			}
		);
	},
	tick_period => 1,
	on_tick => \&check_incoming_event,
	#on_tick => \&get_incoming_event,
)->start;

sub check_incoming_event () {
	($serv) = @_;
	$msg = $mq->get(1, "incoming");
	print $msg->{body} . "\n" if $msg->{body};
	$event_str = $msg->{body};
	local %hash = &Json2Hash($event_str);
	for $uuid (keys %incoming_connections) {
		if ((($hash{from} eq $incoming_connections{$uuid}{agent}) ||
				($hash{to} eq $incoming_connections{$uuid}{agent})) &&
			$hash{domain_name} eq $incoming_connections{$uuid}{domain_name}) {
			$incoming_connections{$uuid}{conn}->send_utf8($event_str) if $event_str;
		}
	}

}

#########################################
#Date 21-10-2020  
#Developed by : Atul akabari
#Purpose : for check websocket connection feasibility
sub get_incoming_event()
{
	$msg123="Hello we are executing Get incoming event function Thanks";
#	print $msg . "\n" if $msg;
	($serv) = @_;
        $msg = $mq->get(1, "incoming");
	print $msg->{body} . "\n" if $msg->{body};
	$event_str = $msg->{body};
	print $msg->{body};
	print $msg123;
}
##############END################
sub check_connection () {
local ($connection) = @_;
	for $uuid (keys %incoming_connections) {
		if ($incoming_connections{$uuid}{conn} == $connection) {
		return $uuid;
		}
	}
}

