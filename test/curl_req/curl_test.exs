defmodule CurlReq.CurlTest do
  use ExUnit.Case, async: true
  doctest CurlReq.Curl

  alias CurlReq.Request

  describe "encode/2" do
    test "req flavor renders every accept encoding" do
      request =
        %Request{}
        |> Request.put_url(URI.parse("https://example.com"))
        |> Request.put_compression([:zstd, :gzip])

      assert ~S(curl -H "accept-encoding: zstd, gzip" -X GET https://example.com) ==
               CurlReq.Curl.encode(request, flavor: :req)
    end

    test "curl flavor renders --compressed for multiple encodings" do
      request =
        %Request{}
        |> Request.put_url(URI.parse("https://example.com"))
        |> Request.put_compression([:zstd, :gzip])

      assert ~S(curl --compressed -X GET https://example.com) == CurlReq.Curl.encode(request)
    end
  end
end
