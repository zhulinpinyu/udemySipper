defmodule UdemySipper do
  def playlist do
    token = "aSL5hOb3ZCt9AZNa590bFNU3JP1BpwVipsxiVWg9"
    url = "https://www.udemy.com/api-2.0/courses/1039062/cached-subscriber-curriculum-items?page_size=9999&fields%5Basset%5D=filename,asset_type"
    headers = ["Authorization": "Bearer #{token}"]
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, headers)
    %{"results" => results} = Poison.Parser.parse!(body)
    lectures = results
                |> Enum.filter(fn(%{"_class" => class}) -> class === "lecture" end )
                |> Enum.filter(fn(%{"asset" => %{"asset_type" => type}}) -> type === "Video" end)
                |> Enum.map(&map_lecture/1)
    IO.inspect lectures
  end

  defp map_lecture(%{"id" => id, "asset" => %{"filename" => filename}}) do
    filename = Path.basename(filename, "mov") <> "mp4"
    %{id: id, filename: filename}
  end
end
