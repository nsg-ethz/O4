#include <core.p4>
#include <tofino.p4>
#include <tofino1arch.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x800;
const ether_type_t ETHERTYPE_VLAN = 16w0x810;
typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> udp_total_len;
    bit<16> checksum;
}

header aes_inout_h {
    bit<8> s00;
    bit<8> s01;
    bit<8> s02;
    bit<8> s03;
    bit<8> s10;
    bit<8> s11;
    bit<8> s12;
    bit<8> s13;
    bit<8> s20;
    bit<8> s21;
    bit<8> s22;
    bit<8> s23;
    bit<8> s30;
    bit<8> s31;
    bit<8> s32;
    bit<8> s33;
}

header aes_meta_h {
    bit<16> dest_port;
    bit<8>  curr_round;
    bit<8>  ff;
}

header copyright_h {
    bit<64> copy;
}

struct header_t {
    ethernet_h  ethernet;
    ipv4_h      ipv4;
    tcp_h       tcp;
    udp_h       udp;
    aes_inout_h aes;
    aes_meta_h  aes_meta;
    copyright_h copy;
}

header aes_tmp_h {
    bit<32> v00;
    bit<32> v01;
    bit<32> v02;
    bit<32> v03;
    bit<32> v10;
    bit<32> v11;
    bit<32> v12;
    bit<32> v13;
    bit<32> v20;
    bit<32> v21;
    bit<32> v22;
    bit<32> v23;
    bit<32> v30;
    bit<32> v31;
    bit<32> v32;
    bit<32> v33;
    bit<32> s0a;
    bit<32> s1a;
    bit<32> s2a;
    bit<32> s3a;
    bit<32> s0b;
    bit<32> s1b;
    bit<32> s2b;
    bit<32> s3b;
}

struct ig_metadata_t {
    bool      recirc;
    bit<9>    rnd_port_for_recirc;
    bit<1>    rnd_bit;
    aes_tmp_h aes_tmp;
}

struct eg_metadata_t {
}

parser TofinoIngressParser(packet_in pkt, inout ig_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1: parse_resubmit;
            0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        pkt.advance(64);
        transition accept;
    }
    state parse_port_metadata {
        pkt.advance(64);
        transition accept;
    }
}

parser SwitchIngressParser(packet_in pkt, out header_t hdr, out ig_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;
    state start {
        tofino_parser.apply(pkt, ig_md, ig_intr_md);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: reject;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP: parse_tcp;
            IP_PROTOCOLS_UDP: parse_udp;
            default: accept;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition select(hdr.ipv4.total_len) {
            default: accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            5555: parse_aes;
            5555 + 1: parse_aes_and_meta;
            default: accept;
        }
    }
    state parse_aes {
        pkt.extract(hdr.aes);
        transition accept;
    }
    state parse_aes_and_meta {
        pkt.extract(hdr.aes);
        pkt.extract(hdr.aes_meta);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout header_t hdr, in ig_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    Checksum() ipv4_checksum;
    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.aes);
        pkt.emit(hdr.aes_meta);
        pkt.emit(hdr.copy);
    }
}

parser SwitchEgressParser(packet_in pkt, out header_t hdr, out eg_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control SwitchEgressDeparser(packet_out pkt, inout header_t hdr, in eg_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
    }
}

control SwitchIngress(inout header_t hdr, inout ig_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action drop() {
        ig_intr_dprsr_md.drop_ctl = 0x1;
    }
    action nop() {
    }
    action reflect() {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
    action route_to(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    Random<bit<1>>() rng;
    action get_rnd_bit() {
        ig_md.rnd_bit = rng.get();
    }
    action do_recirculate() {
        route_to(ig_md.rnd_port_for_recirc);
    }
    action write_v_0_0_a(bit<32> v) {
        ig_md.aes_tmp.v00 = v;
    }
    table tb_lookup_0_0_t {
        key = {
            hdr.aes.s00            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_0_0_a;
        }
    }
    action write_v_0_1_a(bit<32> v) {
        ig_md.aes_tmp.v01 = v;
    }
    table tb_lookup_0_1_t {
        key = {
            hdr.aes.s01            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_0_1_a;
        }
    }
    action write_v_0_2_a(bit<32> v) {
        ig_md.aes_tmp.v02 = v;
    }
    table tb_lookup_0_2_t {
        key = {
            hdr.aes.s02            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_0_2_a;
        }
    }
    action write_v_0_3_a(bit<32> v) {
        ig_md.aes_tmp.v03 = v;
    }
    table tb_lookup_0_3_t {
        key = {
            hdr.aes.s03            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_0_3_a;
        }
    }
    action write_v_1_0_a(bit<32> v) {
        ig_md.aes_tmp.v10 = v;
    }
    table tb_lookup_1_0_t {
        key = {
            hdr.aes.s10            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_1_0_a;
        }
    }
    action write_v_1_1_a(bit<32> v) {
        ig_md.aes_tmp.v11 = v;
    }
    table tb_lookup_1_1_t {
        key = {
            hdr.aes.s11            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_1_1_a;
        }
    }
    action write_v_1_2_a(bit<32> v) {
        ig_md.aes_tmp.v12 = v;
    }
    table tb_lookup_1_2_t {
        key = {
            hdr.aes.s12            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_1_2_a;
        }
    }
    action write_v_1_3_a(bit<32> v) {
        ig_md.aes_tmp.v13 = v;
    }
    table tb_lookup_1_3_t {
        key = {
            hdr.aes.s13            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_1_3_a;
        }
    }
    action write_v_2_0_a(bit<32> v) {
        ig_md.aes_tmp.v20 = v;
    }
    table tb_lookup_2_0_t {
        key = {
            hdr.aes.s20            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_2_0_a;
        }
    }
    action write_v_2_1_a(bit<32> v) {
        ig_md.aes_tmp.v21 = v;
    }
    table tb_lookup_2_1_t {
        key = {
            hdr.aes.s21            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_2_1_a;
        }
    }
    action write_v_2_2_a(bit<32> v) {
        ig_md.aes_tmp.v22 = v;
    }
    table tb_lookup_2_2_t {
        key = {
            hdr.aes.s22            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_2_2_a;
        }
    }
    action write_v_2_3_a(bit<32> v) {
        ig_md.aes_tmp.v23 = v;
    }
    table tb_lookup_2_3_t {
        key = {
            hdr.aes.s23            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_2_3_a;
        }
    }
    action write_v_3_0_a(bit<32> v) {
        ig_md.aes_tmp.v30 = v;
    }
    table tb_lookup_3_0_t {
        key = {
            hdr.aes.s30            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_3_0_a;
        }
    }
    action write_v_3_1_a(bit<32> v) {
        ig_md.aes_tmp.v31 = v;
    }
    table tb_lookup_3_1_t {
        key = {
            hdr.aes.s31            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_3_1_a;
        }
    }
    action write_v_3_2_a(bit<32> v) {
        ig_md.aes_tmp.v32 = v;
    }
    table tb_lookup_3_2_t {
        key = {
            hdr.aes.s32            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_3_2_a;
        }
    }
    action write_v_3_3_a(bit<32> v) {
        ig_md.aes_tmp.v33 = v;
    }
    table tb_lookup_3_3_t {
        key = {
            hdr.aes.s33            : exact;
            hdr.aes_meta.curr_round: exact;
        }
        size = 3600;
        actions = {
            write_v_3_3_a;
        }
    }
    action xor_s_0_ini() {
        ig_md.aes_tmp.s0a = ig_md.aes_tmp.v00 ^ ig_md.aes_tmp.v11;
        ig_md.aes_tmp.s0b = ig_md.aes_tmp.v22 ^ ig_md.aes_tmp.v33;
    }
    action xor_s_1_ini() {
        ig_md.aes_tmp.s1a = ig_md.aes_tmp.v10 ^ ig_md.aes_tmp.v21;
        ig_md.aes_tmp.s1b = ig_md.aes_tmp.v32 ^ ig_md.aes_tmp.v03;
    }
    action xor_s_2_ini() {
        ig_md.aes_tmp.s2a = ig_md.aes_tmp.v20 ^ ig_md.aes_tmp.v31;
        ig_md.aes_tmp.s2b = ig_md.aes_tmp.v02 ^ ig_md.aes_tmp.v13;
    }
    action xor_s_3_ini() {
        ig_md.aes_tmp.s3a = ig_md.aes_tmp.v30 ^ ig_md.aes_tmp.v01;
        ig_md.aes_tmp.s3b = ig_md.aes_tmp.v12 ^ ig_md.aes_tmp.v23;
    }
    action xor_s_0_fin() {
        hdr.aes.s00 = ig_md.aes_tmp.s0a[31:24] ^ ig_md.aes_tmp.s0b[31:24];
        hdr.aes.s01 = ig_md.aes_tmp.s0a[23:16] ^ ig_md.aes_tmp.s0b[23:16];
        hdr.aes.s02 = ig_md.aes_tmp.s0a[15:8] ^ ig_md.aes_tmp.s0b[15:8];
        hdr.aes.s03 = ig_md.aes_tmp.s0a[7:0] ^ ig_md.aes_tmp.s0b[7:0];
    }
    action xor_s_1_fin() {
        hdr.aes.s10 = ig_md.aes_tmp.s1a[31:24] ^ ig_md.aes_tmp.s1b[31:24];
        hdr.aes.s11 = ig_md.aes_tmp.s1a[23:16] ^ ig_md.aes_tmp.s1b[23:16];
        hdr.aes.s12 = ig_md.aes_tmp.s1a[15:8] ^ ig_md.aes_tmp.s1b[15:8];
        hdr.aes.s13 = ig_md.aes_tmp.s1a[7:0] ^ ig_md.aes_tmp.s1b[7:0];
    }
    action xor_s_2_fin() {
        hdr.aes.s20 = ig_md.aes_tmp.s2a[31:24] ^ ig_md.aes_tmp.s2b[31:24];
        hdr.aes.s21 = ig_md.aes_tmp.s2a[23:16] ^ ig_md.aes_tmp.s2b[23:16];
        hdr.aes.s22 = ig_md.aes_tmp.s2a[15:8] ^ ig_md.aes_tmp.s2b[15:8];
        hdr.aes.s23 = ig_md.aes_tmp.s2a[7:0] ^ ig_md.aes_tmp.s2b[7:0];
    }
    action xor_s_3_fin() {
        hdr.aes.s30 = ig_md.aes_tmp.s3a[31:24] ^ ig_md.aes_tmp.s3b[31:24];
        hdr.aes.s31 = ig_md.aes_tmp.s3a[23:16] ^ ig_md.aes_tmp.s3b[23:16];
        hdr.aes.s32 = ig_md.aes_tmp.s3a[15:8] ^ ig_md.aes_tmp.s3b[15:8];
        hdr.aes.s33 = ig_md.aes_tmp.s3a[7:0] ^ ig_md.aes_tmp.s3b[7:0];
    }
    action incr_and_recirc(bit<8> next_round) {
        hdr.aes_meta.curr_round = next_round;
        do_recirculate();
        hdr.copy.setInvalid();
        hdr.udp.dst_port = 5555 + 1;
    }
    action do_not_recirc() {
        route_to((bit<9>)hdr.aes_meta.dest_port);
        hdr.udp.dst_port = 5555;
        hdr.aes_meta.setInvalid();
        hdr.copy.setValid();
        hdr.copy.copy = 0xa9204147504c7633;
        hdr.udp.udp_total_len = 8 + 16 + 8;
        hdr.ipv4.total_len = 8 + 16 + 8 + 20;
    }
    action do_not_recirc_final_xor(bit<8> s00, bit<8> s01, bit<8> s02, bit<8> s03, bit<8> s10, bit<8> s11, bit<8> s12, bit<8> s13, bit<8> s20, bit<8> s21, bit<8> s22, bit<8> s23, bit<8> s30, bit<8> s31, bit<8> s32, bit<8> s33) {
        do_not_recirc();
        hdr.aes.s00 = hdr.aes.s00 ^ s00;
        hdr.aes.s01 = hdr.aes.s01 ^ s01;
        hdr.aes.s02 = hdr.aes.s02 ^ s02;
        hdr.aes.s03 = hdr.aes.s03 ^ s03;
        hdr.aes.s10 = hdr.aes.s10 ^ s10;
        hdr.aes.s11 = hdr.aes.s11 ^ s11;
        hdr.aes.s12 = hdr.aes.s12 ^ s12;
        hdr.aes.s13 = hdr.aes.s13 ^ s13;
        hdr.aes.s20 = hdr.aes.s20 ^ s20;
        hdr.aes.s21 = hdr.aes.s21 ^ s21;
        hdr.aes.s22 = hdr.aes.s22 ^ s22;
        hdr.aes.s23 = hdr.aes.s23 ^ s23;
        hdr.aes.s30 = hdr.aes.s30 ^ s30;
        hdr.aes.s31 = hdr.aes.s31 ^ s31;
        hdr.aes.s32 = hdr.aes.s32 ^ s32;
        hdr.aes.s33 = hdr.aes.s33 ^ s33;
    }
    table tb_recirc_decision {
        key = {
            hdr.aes_meta.curr_round: exact;
        }
        actions = {
            incr_and_recirc;
            do_not_recirc;
            do_not_recirc_final_xor;
        }
        size = 20;
        default_action = do_not_recirc;
    }
    apply {
        bool is_aes = hdr.aes.isValid();
        if (!is_aes) {
            drop();
            exit;
        }
        if (!hdr.aes_meta.isValid()) {
            hdr.aes_meta.setValid();
            hdr.aes_meta.curr_round = 0;
            hdr.aes_meta.ff = 0xff;
            hdr.aes_meta.dest_port = (bit<16>)ig_intr_md.ingress_port;
            hdr.udp.checksum = 0;
        }
        get_rnd_bit();
        if (ig_md.rnd_bit == 0) {
            ig_md.rnd_port_for_recirc = 68;
        } else {
            ig_md.rnd_port_for_recirc = 68 + 128;
        }
        tb_lookup_0_0_t.apply();
        tb_lookup_0_1_t.apply();
        tb_lookup_0_2_t.apply();
        tb_lookup_0_3_t.apply();
        tb_lookup_1_0_t.apply();
        tb_lookup_1_1_t.apply();
        tb_lookup_1_2_t.apply();
        tb_lookup_1_3_t.apply();
        tb_lookup_2_0_t.apply();
        tb_lookup_2_1_t.apply();
        tb_lookup_2_2_t.apply();
        tb_lookup_2_3_t.apply();
        tb_lookup_3_0_t.apply();
        tb_lookup_3_1_t.apply();
        tb_lookup_3_2_t.apply();
        tb_lookup_3_3_t.apply();
        xor_s_0_ini();
        xor_s_0_fin();
        xor_s_1_ini();
        xor_s_1_fin();
        xor_s_2_ini();
        xor_s_2_fin();
        xor_s_3_ini();
        xor_s_3_fin();
        tb_recirc_decision.apply();
    }
}

control SwitchEgress(inout header_t hdr, inout eg_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

Pipeline(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch(pipe) main;

