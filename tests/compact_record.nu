use ../utils/compact_record.nu 

const $TEST_INPUT_RECORD = {
    NumberValue: 12345,
    StringValue: "test string",
    NullValue: null,
    EmptyString: "",
    EmptyArray: [],
    EmptyRecord: {},
    ZeroNumberValue: 0,
    BooleanStringValueTrue: "true",
    BooleanStringValueFalse: "false",
    BooleanValueTrue: true,
    BooleanValueFalse: false,
}

export def `Remove 'null' values from record` [] {
    let $result = $TEST_INPUT_RECORD | compact_record
    assert equal $result ($TEST_INPUT_RECORD | reject NullValue)
}

export def `Remove 'null' and empty values from record` [] {
    let $result = $TEST_INPUT_RECORD | compact_record --remove-empty 
    assert equal $result ($TEST_INPUT_RECORD | reject NullValue EmptyString EmptyArray EmptyRecord)
}

export def `Remove specified fields form list of keys record` [] {
    let $result = $TEST_INPUT_RECORD | select NumberValue StringValue | compact_record StringValue
    assert equal $result ($TEST_INPUT_RECORD | select NumberValue)
}