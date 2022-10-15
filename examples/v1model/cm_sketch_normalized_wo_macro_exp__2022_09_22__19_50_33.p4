#lang halstead/p4

#include <core.p4>
#include <v1model.p4>



const bit<16> TYPE_IPV4 = 0x800;

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;


header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
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

struct metadata {
    bit<32> index_sketch0;
    bit<32> index_sketch1;
    bit<32> index_sketch2;
    bit<32> index_sketch3;
    bit<32> index_sketch4;
    bit<32> index_sketch5;
    bit<32> index_sketch6;
    bit<32> index_sketch7;

    bit<64> value_sketch0;
    bit<64> value_sketch1;
    bit<64> value_sketch2;
    bit<64> value_sketch3;
    bit<64> value_sketch4;
    bit<64> value_sketch5;
    bit<64> value_sketch6;
    bit<64> value_sketch7;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
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
            6 : parse_tcp;
            default: accept;
        }
    }

    state parse_tcp {
packet.extract(hdr.tcp);
        transition accept;
    }
}



control MyDeparser(packet_out packet, in headers hdr) {
    apply {

        
packet.emit(hdr.ethernet);
packet.emit(hdr.ipv4);

        
packet.emit(hdr.tcp);
    }
}


#define SKETCH_BUCKET_LENGTH 28
#define SKETCH_CELL_BIT_WIDTH 64

#define SKETCH_REGISTER(num) register<bit<SKETCH_CELL_BIT_WIDTH>>(SKETCH_BUCKET_LENGTH) sketch##num



#define SKETCH_COUNT(num, algorithm) hash(meta.index_sketch##num, HashAlgorithm.algorithm, (bit<16>)0, {hdr.ipv4.srcAddr, \
 hdr.ipv4.dstAddr, hdr.tcp.srcPort, hdr.tcp.dstPort, hdr.ipv4.protocol}, (bit<32>)SKETCH_BUCKET_LENGTH);\
 sketch##num.read(meta.value_sketch##num, meta.index_sketch##num); \
 meta.value_sketch##num = meta.value_sketch##num +1; \
 sketch##num.write(meta.index_sketch##num, meta.value_sketch##num)



control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}



control MyIngress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {

SKETCH_REGISTER(0);
SKETCH_REGISTER(1);
SKETCH_REGISTER(2);
    
    

action drop() {
mark_to_drop(standard_metadata);
    }

action sketch_count(){
SKETCH_COUNT(0, crc32_custom);
SKETCH_COUNT(1, crc32_custom);
SKETCH_COUNT(2, crc32_custom);
        
        
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

    apply {

        
if (hdr.ipv4.isValid() && hdr.tcp.isValid()){
sketch_count();
        }

forwarding.apply();
    }
}



control MyEgress(inout headers hdr,  inout metadata meta,  inout standard_metadata_t standard_metadata) {
    apply {
    }
}



control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
    }
}




MyDeparser() ) main;