defmodule Protobuf.Protoc.CLI do
  def main(_) do
    # https://groups.google.com/forum/#!topic/elixir-lang-talk/T5enez_BBTI
    :io.setopts(:standard_io, encoding: :latin1)
    bin = IO.binread(:all)
    request = Protobuf.Decoder.decode(bin, Google_Protobuf_Compiler.CodeGeneratorRequest)
    # debug
    # raise inspect(request, limit: :infinity)
    ctx = %Protobuf.Protoc.Context{}
    ctx = parse_params(ctx, request.parameter)
    ctx = find_package_names(ctx, request.proto_file)
    files = Enum.filter_map(request.proto_file, fn(desc) ->
      Enum.member?(request.file_to_generate, desc.name)
    end, fn(desc) ->
      Protobuf.Protoc.Generator.generate(ctx, desc)
    end)
    response = %Google_Protobuf_Compiler.CodeGeneratorResponse{file: files}
    IO.binwrite(Protobuf.Encoder.encode(response))
  end

  def parse_params(ctx, nil), do: ctx
  def parse_params(ctx, params_str) when is_binary(params_str) do
    params = String.split(params_str, ",")
    parse_params(ctx, params)
  end
  def parse_params(ctx, ["plugins=" <> plugins|t]) do
    plugins = String.split(plugins, "+")
    ctx = %{ctx|plugins: plugins}
    parse_params(ctx, t)
  end
  def parse_params(ctx, []), do: ctx

  defp find_package_names(ctx, descs) do
    find_package_names(ctx, descs, %{})
  end
  defp find_package_names(ctx, [], acc), do: %{ctx|pkg_mapping: acc}
  defp find_package_names(ctx, [desc|t], acc) do
    find_package_names(ctx, t, Map.put(acc, desc.name, desc.package))
  end
end
