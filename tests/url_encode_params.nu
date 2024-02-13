use std assert
use ../utils/url_encode_params.nu

export def `Url encode params` [] {
    assert equal (
        url_encode_params { id: 10}
    ) (
        { id: "10" }
    )
}