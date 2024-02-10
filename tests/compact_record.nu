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
}

export def "Remove 'null' values from record" [] {
    let $result = (compact_record $TEST_INPUT_RECORD) 
    assert equal $result ($TEST_INPUT_RECORD | reject NullValue)
}

export def "Remove 'null' and empty values from record" [] {
    let $result = (compact_record $TEST_INPUT_RECORD --remove-empty) 
    assert equal $result ($TEST_INPUT_RECORD | reject NullValue EmptyString EmptyArray EmptyRecord)
}