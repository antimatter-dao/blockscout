defmodule Explorer.SmartContract.RustVerifierInterface do
  alias HTTPoison.Response

  def test() do
    verify_multi_part(%{
      creation_bytecode:
        "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea2646970667358221220401384b635c9b2ff0b06fbc9e7e8267636d69fab59d76aa5488c3440644e376264736f6c63430008070033",
      deployed_bytecode:
        "0x6080604052600080fdfea2646970667358221220401384b635c9b2ff0b06fbc9e7e8267636d69fab59d76aa5488c3440644e376264736f6c63430008070033",
      compiler_version: "v0.8.7+commit.e28d00a7",
      sources: %{
        "source.sol" => "pragma solidity >=0.7.0 <0.9.0; contract Main {uint256 a; }"
      },
      evm_version: "london",
      optimization_runs: nil,
      contract_libraries: nil
    })
    |> debug("wtf")
  end

  def verify_multi_part(
        %{
          creation_bytecode: creation_bytecode,
          deployed_bytecode: deployed_bytecode,
          compiler_version: compiler_version,
          sources: sources,
          evm_version: evm_version,
          optimization_runs: optimization_runs,
          contract_libraries: contract_libraries
        } = body
      ) do
    http_post_request(multiple_files_verification_url(), body)
  end

  def http_post_request(url, body) do
    headers = [{"Content-Type", "application/json"}]
    # url = Application.get_env(:explorer, __MODULE__)[:table_url]

    # body = %{
    #   "typecast" => true,
    #   "records" => [%{"fields" => PublicTagsRequest.to_map(new_request)}]
    # }
    case HTTPoison.post(url, Jason.encode!(body), headers) do
      {:ok, %Response{body: body, status_code: 200}} ->
        proccess_verifier_response(body)

      {:ok, %Response{body: body, status_code: _}} ->
        proccess_verifier_response(body)

      {:error, _} ->
        {:error, "Error while sending request to verification microservice"}
        # log error
    end
  end

  def http_get_request(url) do
    case HTTPoison.get(url) do
      {:ok, %Response{body: body, status_code: 200}} ->
        {:ok, body}

      {:ok, %Response{body: body, status_code: _}} ->
        {:error, body}

      {:error, _} ->
        {:error, "Error while sending request to verification microservice"}
    end
  end

  def get_versions_list() do
    case http_get_request(versions_list_url()) do
      {:ok, list} ->
        list

      _ ->
        []
    end
  end

  defp debug(value, key) do
    require Logger
    Logger.configure(truncate: :infinity)
    Logger.info(key)
    Logger.info(Kernel.inspect(value, limit: :infinity, printable_limit: :infinity))
    value
  end

  def proccess_verifier_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} ->
        proccess_verifier_response(decoded)

      _ ->
        {:error, body}
    end
  end

  def proccess_verifier_response(%{"status" => zero, "result" => result}) when zero in ["0", 0] do
    {:ok, result}
  end

  def proccess_verifier_response(%{"status" => one, "message" => error}) when zero in ["1", 1] do
    {:error, error}
  end

  def proccess_verifier_response(%{"versions" => versions}), do: {:ok, versions}

  def proccess_verifier_response(other), do: {:error, other}

  def multiple_files_verification_url(), do: "#{base_url()}" <> "/api/v1/solidity/verify/multiple-files"

  def versions_list_url(), do: "#{base_url()}" <> "/api/v1/solidity/versions"

  def base_url(), do: Application.get_env(:explorer, __MODULE__)[:service_url]

  def enabled?(), do: Application.get_env(:explorer, __MODULE__)[:enabled]
end

# Explorer.SmartContract.RustVerifierInterface.test()
