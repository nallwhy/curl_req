defmodule CurlReq.RequestTest do
  use ExUnit.Case, async: true
  doctest CurlReq.Request

  alias CurlReq.Request
  import CurlReq.Request

  describe "put_body/2" do
    test "decode form" do
      request =
        %Request{}
        |> put_encoding(:form)
        |> put_body("foo=bar")

      assert %{"foo" => "bar"} = request.body
    end

    test "decode json" do
      request =
        %Request{}
        |> put_encoding(:json)
        |> put_body(~s({"foo":"bar"}))

      assert %{"foo" => "bar"} = request.body
    end
  end

  describe "put_encoding/2" do
    test "raw to form" do
      request =
        %Request{}
        |> put_encoding(:raw)
        |> put_body("foo=bar")
        |> put_encoding(:form)

      assert %{"foo" => "bar"} = request.body
    end

    test "raw to json" do
      request =
        %Request{}
        |> put_encoding(:raw)
        |> put_body(~s({"foo":"bar"}))
        |> put_encoding(:json)

      assert %{"foo" => "bar"} = request.body
    end

    test "form to raw" do
      request =
        %Request{}
        |> put_encoding(:form)
        |> put_body(%{"foo" => "bar"})
        |> put_encoding(:raw)

      assert :raw == request.encoding
      assert "foo=bar" == request.body
    end

    test "json to raw" do
      request =
        %Request{}
        |> put_encoding(:json)
        |> put_body(%{"foo" => "bar"})
        |> put_encoding(:raw)

      assert :raw == request.encoding
      assert ~s({"foo":"bar"}) == request.body
    end

    test "json to form" do
      request =
        %Request{}
        |> put_encoding(:form)
        |> put_body(%{"foo" => "bar"})
        |> put_encoding(:json)

      assert %{"foo" => "bar"} = request.body
    end

    test "from and to same encoding is noop" do
      request =
        %Request{}
        |> put_encoding(:form)
        |> put_body(%{"foo" => "bar"})
        |> put_encoding(:form)
        |> put_encoding(:form)
        |> put_encoding(:form)

      assert %{"foo" => "bar"} = request.body
    end
  end

  describe "put_header/3 with accept-encoding" do
    test "comma separated supported encodings set compression in preference order" do
      request = put_header(%Request{}, "accept-encoding", ["zstd, gzip"])

      assert request.compression == :zstd
      assert request.accept_encodings == [:zstd, :gzip]
      refute Map.has_key?(request.headers, "accept-encoding")
    end

    test "unsupported encoding is kept as a raw header" do
      request = put_header(%Request{}, "accept-encoding", ["gzip, deflate"])

      assert request.compression == :none
      assert request.headers["accept-encoding"] == ["gzip, deflate"]
    end
  end

  describe "put_compression/2" do
    test "list of encodings uses the first one as compression" do
      request = put_compression(%Request{}, [:br, :gzip])

      assert request.compression == :br
      assert request.accept_encodings == [:br, :gzip]
    end

    test "true keeps encodings that are already set" do
      request =
        %Request{}
        |> put_compression([:zstd, :gzip])
        |> put_compression(true)

      assert request.compression == :zstd
      assert request.accept_encodings == [:zstd, :gzip]
    end

    test "false clears all encodings" do
      request =
        %Request{}
        |> put_compression([:zstd, :gzip])
        |> put_compression(false)

      assert request.compression == :none
      assert request.accept_encodings == []
    end
  end

  describe "put_protocols/2" do
    for proto <- [:http1_0, :http1_1, :http2] do
      @tag proto: proto
      test "set #{inspect(proto)}", %{proto: proto} do
        request =
          %Request{}
          |> put_protocols([proto])

        assert request.protocols == [proto]
      end
    end
  end
end
