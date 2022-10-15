header header_t {
    bit<32> values_0;
    bit<32> values_1;
    bit<32> values_2;
    bit<32> values_3;
}
struct headers {
    header_t test_header;
}
control test_control(inout headers hdr) {
    action test_action_call_3__bit_32__3() {
        hdr.test_header.values_3 = (bit<32>)3;
    }
    action test_action_call_2__bit_32__2() {
        hdr.test_header.values_2 = (bit<32>)2;
    }
    action test_action_call_1__bit_32__1() {
        hdr.test_header.values_1 = (bit<32>)1;
    }
    action test_action_call_0__bit_32__0() {
        hdr.test_header.values_0 = (bit<32>)0;
    }
    apply {
        {
            {
                test_action_call_0__bit_32__0();
            }
        }
        {
            {
                test_action_call_1__bit_32__1();
            }
        }
        {
            {
                test_action_call_2__bit_32__2();
            }
        }
        {
            {
                test_action_call_3__bit_32__3();
            }
        }
    }
}