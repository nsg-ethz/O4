#lang halstead/p4

#include <core.p4>
#include <v1model.p4>



const bit<16> TYPE_IPV4 = 0x800;
const bit<8>  TYPE_TCP  = 6;
const bit<8>  TYPE_UDP  = 17;
const bit<8>  TYPE_LOSS = 0xFC;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;


header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header loss_t {

    bit<1> batch_id;
    bit<7> padding; 
    bit<8> nextProtocol;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    dscp;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<1>  cwr;
    bit<1>  ece;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  psh;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t{
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}

struct metadata {

    bit<16> tmp_src_port;
    bit<16> tmp_dst_port;

    bit<16> um_h1;
    bit<16> um_h2;
    bit<16> um_h3;

    bit<16> dm_h1;
    bit<16> dm_h2;
    bit<16> dm_h3;

    bit<64> tmp_ip_src;
    bit<64> tmp_ip_dst;
    bit<64> tmp_ports_proto_id;
    bit<64> tmp_counter;

    bit<16> previous_batch_id;
    bit<16> batch_id;
    bit<16> last_local_batch_id;

    bit<1> dont_execute_um;
    bit<1> dont_execute_dm;

}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    loss_t       loss;
    tcp_t        tcp;
    udp_t        udp;
}




parser MyParser(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

    state start {

        transition parse_ethernet;

    }

    state parse_ethernet {

packet.extract(hdr.ethernet);
transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
packet.extract(hdr.ipv4);
transition select(hdr.ipv4.protocol){
            TYPE_TCP : parse_tcp;
            TYPE_UDP : parse_udp;
            TYPE_LOSS : parse_loss;
            default: accept;
        }
    }

    state parse_tcp {
packet.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
packet.extract(hdr.udp);
        transition accept;
    }

    state parse_loss {
packet.extract(hdr.loss);
transition select(hdr.loss.nextProtocol){
            TYPE_TCP : parse_tcp;
            TYPE_UDP : parse_udp;
            default: accept;
        }
    }
}



control MyDeparser(packet_out packet, in headers hdr) {
    apply {

        
packet.emit(hdr.ethernet);
packet.emit(hdr.ipv4);
packet.emit(hdr.loss);
packet.emit(hdr.tcp);
packet.emit(hdr.udp);
    }
}


#define NUM_PORTS 2
#define NUM_BATCHES 2

#define REGISTER_SIZE_TOTAL 2048 
#define REGISTER_BATCH_SIZE REGISTER_SIZE_TOTAL/NUM_BATCHES
#define REGISTER_PORT_SIZE REGISTER_BATCH_SIZE/NUM_PORTS

#define REGISTER_CELL_WIDTH 64

#define LOSS_CHANGE_OF_BATCH 0x1234



control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}



control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

register<bit<16>>(1) last_batch_id;

register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_ip_src;
register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_ip_dst;
register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_ports_proto_id;
register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) um_counter;

register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_ip_src;
register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_ip_dst;
register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_ports_proto_id;
register<bit<REGISTER_CELL_WIDTH>>(REGISTER_SIZE_TOTAL) dm_counter;

action drop() {
mark_to_drop(standard_metadata);
    }

action compute_hash_indexes(){

         
hash(meta.um_h1, HashAlgorithm.crc32_custom, ((meta.batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.egress_spec-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,hdr.ipv4.dstAddr,
 meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
hash(meta.um_h2, HashAlgorithm.crc32_custom, ((meta.batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.egress_spec-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,hdr.ipv4.dstAddr,
 meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
hash(meta.um_h3, HashAlgorithm.crc32_custom, ((meta.batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.egress_spec-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,hdr.ipv4.dstAddr,
 meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);

        
hash(meta.dm_h1, HashAlgorithm.crc32_custom, ((meta.previous_batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.ingress_port-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,hdr.ipv4.dstAddr,
 meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
hash(meta.dm_h2, HashAlgorithm.crc32_custom, ((meta.previous_batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.ingress_port-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,hdr.ipv4.dstAddr,
 meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
hash(meta.dm_h3, HashAlgorithm.crc32_custom, ((meta.previous_batch_id * REGISTER_BATCH_SIZE) + ((((bit<16>)standard_metadata.ingress_port-1)*REGISTER_PORT_SIZE))), {hdr.ipv4.srcAddr,hdr.ipv4.dstAddr,
 meta.tmp_src_port, meta.tmp_dst_port, hdr.loss.nextProtocol, hdr.ipv4.identification}, (bit<16>)REGISTER_PORT_SIZE);
    }

action apply_um_meter(){

        
        
bit<64> tmp = (bit<64>)hdr.ipv4.srcAddr;
um_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.um_h1);
meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
um_ip_src.write((bit<32>)meta.um_h1, meta.tmp_ip_src);

        
um_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.um_h2);
meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
um_ip_src.write((bit<32>)meta.um_h2, meta.tmp_ip_src);

        
um_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.um_h3);
meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
um_ip_src.write((bit<32>)meta.um_h3, meta.tmp_ip_src);

        
tmp = (bit<64>)hdr.ipv4.dstAddr;
um_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.um_h1);
meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
um_ip_dst.write((bit<32>)meta.um_h1, meta.tmp_ip_dst);

        
um_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.um_h2);
meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
um_ip_dst.write((bit<32>)meta.um_h2, meta.tmp_ip_dst);

        
um_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.um_h3);
meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
um_ip_dst.write((bit<32>)meta.um_h3, meta.tmp_ip_dst);

        
        
tmp = (bit<8>)0 ++ meta.tmp_src_port ++ meta.tmp_dst_port ++ hdr.loss.nextProtocol ++ hdr.ipv4.identification;
um_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.um_h1);
meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
um_ports_proto_id.write((bit<32>)meta.um_h1, meta.tmp_ports_proto_id);

        
um_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.um_h2);
meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
um_ports_proto_id.write((bit<32>)meta.um_h2, meta.tmp_ports_proto_id);

        
um_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.um_h3);
meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
um_ports_proto_id.write((bit<32>)meta.um_h3, meta.tmp_ports_proto_id);

        
        
um_counter.read(meta.tmp_counter, (bit<32>)meta.um_h1);
        meta.tmp_counter = meta.tmp_counter + 1;
um_counter.write((bit<32>)meta.um_h1, meta.tmp_counter);

        
um_counter.read(meta.tmp_counter, (bit<32>)meta.um_h2);
        meta.tmp_counter = meta.tmp_counter + 1;
um_counter.write((bit<32>)meta.um_h2, meta.tmp_counter);

        
um_counter.read(meta.tmp_counter, (bit<32>)meta.um_h3);
        meta.tmp_counter = meta.tmp_counter + 1;
um_counter.write((bit<32>)meta.um_h3, meta.tmp_counter);
    }

action apply_dm_meter(){

        
        
bit<64> tmp = (bit<64>)hdr.ipv4.srcAddr;
dm_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.dm_h1);
meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
dm_ip_src.write((bit<32>)meta.dm_h1, meta.tmp_ip_src);

        
dm_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.dm_h2);
meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
dm_ip_src.write((bit<32>)meta.dm_h2, meta.tmp_ip_src);

        
dm_ip_src.read(meta.tmp_ip_src, (bit<32>)meta.dm_h3);
meta.tmp_ip_src = meta.tmp_ip_src ^ (tmp);
dm_ip_src.write((bit<32>)meta.dm_h3, meta.tmp_ip_src);

        
tmp = (bit<64>)hdr.ipv4.dstAddr;
dm_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.dm_h1);
meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
dm_ip_dst.write((bit<32>)meta.dm_h1, meta.tmp_ip_dst);

        
dm_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.dm_h2);
meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
dm_ip_dst.write((bit<32>)meta.dm_h2, meta.tmp_ip_dst);

        
dm_ip_dst.read(meta.tmp_ip_dst, (bit<32>)meta.dm_h3);
meta.tmp_ip_dst = meta.tmp_ip_dst ^ (tmp);
dm_ip_dst.write((bit<32>)meta.dm_h3, meta.tmp_ip_dst);

        
        
tmp = (bit<8>)0 ++ meta.tmp_src_port ++ meta.tmp_dst_port ++ hdr.loss.nextProtocol ++ hdr.ipv4.identification;
dm_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.dm_h1);
meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
dm_ports_proto_id.write((bit<32>)meta.dm_h1, meta.tmp_ports_proto_id);

        
dm_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.dm_h2);
meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
dm_ports_proto_id.write((bit<32>)meta.dm_h2, meta.tmp_ports_proto_id);

        
dm_ports_proto_id.read(meta.tmp_ports_proto_id, (bit<32>)meta.dm_h3);
meta.tmp_ports_proto_id = meta.tmp_ports_proto_id ^ (tmp);
dm_ports_proto_id.write((bit<32>)meta.dm_h3, meta.tmp_ports_proto_id);

        
        
dm_counter.read(meta.tmp_counter, (bit<32>)meta.dm_h1);
        meta.tmp_counter = meta.tmp_counter + 1;
dm_counter.write((bit<32>)meta.dm_h1, meta.tmp_counter);

        
dm_counter.read(meta.tmp_counter, (bit<32>)meta.dm_h2);
        meta.tmp_counter = meta.tmp_counter + 1;
dm_counter.write((bit<32>)meta.dm_h2, meta.tmp_counter);

        
dm_counter.read(meta.tmp_counter, (bit<32>)meta.dm_h3);
        meta.tmp_counter = meta.tmp_counter + 1;
dm_counter.write((bit<32>)meta.dm_h3, meta.tmp_counter);

    }


action set_egress_port(bit<9> egress_port){
        standard_metadata.egress_spec = egress_port;
    }

    table forwarding {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            set_egress_port;
            drop;
            NoAction;
        }
        size = 64;
        default_action = drop;
    }

action remove_header (){

        bit<8> protocol = hdr.loss.nextProtocol;
hdr.loss.setInvalid();
        hdr.ipv4.protocol = protocol;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen - 2;

        meta.dont_execute_um = 1;
    }

    table remove_loss_header {
        key = {
            standard_metadata.egress_spec: exact;
        }

        actions = {
            remove_header;
            NoAction;
        }
        size=64;
        default_action = NoAction;
    }

    apply {

if (hdr.ipv4.isValid())
        {
if (hdr.tcp.isValid()) {
                meta.tmp_src_port = hdr.tcp.srcPort;
                meta.tmp_dst_port = hdr.tcp.dstPort;
            }
else if (hdr.udp.isValid()) {
                meta.tmp_src_port = hdr.udp.srcPort;
                meta.tmp_dst_port = hdr.udp.dstPort;
            }

forwarding.apply();
            
if (!hdr.loss.isValid()) {
 hdr.loss.setValid();
               hdr.loss.nextProtocol = hdr.ipv4.protocol;
               hdr.ipv4.totalLen = hdr.ipv4.totalLen + 2;
               hdr.ipv4.protocol = TYPE_LOSS;

               meta.dont_execute_dm = 1;
            }
            else {
 meta.previous_batch_id = (bit<16>)hdr.loss.batch_id;
            }
            
meta.batch_id = (bit<16>)((standard_metadata.ingress_global_timestamp >> 21) % 2);
last_batch_id.read(meta.last_local_batch_id, (bit<32>)0);
last_batch_id.write((bit<32>)0, meta.batch_id);

            
            
            
if (meta.batch_id != meta.last_local_batch_id) {
clone3(CloneType.I2E, 100, meta);
            }

            
hdr.loss.batch_id = (bit<1>)meta.batch_id;

compute_hash_indexes();
remove_loss_header.apply();

if (meta.dont_execute_um == 0) {
 apply_um_meter();
            }

if (meta.dont_execute_dm == 0) {
 apply_dm_meter();
            }

            
if (hdr.ipv4.ttl == 1) {
drop();
            } else {
                hdr.ipv4.ttl = hdr.ipv4.ttl -1;
            }
        }
    }
}



control MyEgress(inout headers hdr,  inout metadata meta,  inout standard_metadata_t standard_metadata) {

    apply {
        
if (standard_metadata.instance_type == 1){
hdr.loss.setValid();
hdr.ipv4.setInvalid();
hdr.loss.batch_id = (bit<1>)meta.last_local_batch_id;
hdr.loss.padding = (bit<7>)0;
hdr.loss.nextProtocol = (bit<8>)0;
            hdr.ethernet.etherType = LOSS_CHANGE_OF_BATCH;
truncate((bit<32>)16); 
        }
    }
}



control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	hdr.ipv4.isValid(), { hdr.ipv4.version, 	hdr.ipv4.ihl, hdr.ipv4.dscp, hdr.ipv4.ecn, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);

    }
}




MyDeparser() ) main;