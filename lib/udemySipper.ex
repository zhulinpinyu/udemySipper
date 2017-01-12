defmodule UdemySipper do
  @token "aSL5hOb3ZCt9AZNa590bFNU3JP1BpwVipsxiVWg9"
  @playlist_url "https://www.udemy.com/api-2.0/courses/1039062/cached-subscriber-curriculum-items?page_size=9999&fields%5Basset%5D=filename,asset_type"

  def playlist do
    headers = ["Authorization": "Bearer #{@token}"]
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(@playlist_url, headers)
    %{"results" => results} = Poison.Parser.parse!(body)
    lectures = results
      |> Enum.filter(fn(%{"_class" => class}) -> class === "lecture" end )
      |> Enum.filter(fn(%{"asset" => %{"asset_type" => type}}) -> type === "Video" end)
      |> Enum.map(&map_lecture/1)
      #|> Enum.each(&lecture_detail/1)
    [h|_t] = lectures
    lecture_detail(h)
  end

  defp map_lecture(%{"id" => id, "asset" => %{"filename" => filename}}) do
    filename = Path.basename(filename, "mov") <> "mp4"
    %{id: id, filename: filename}
  end

  defp lecture_detail(%{id: id, filename: _filename}) do
    lecture_url = "https://www.udemy.com/api-2.0/users/me/subscribed-courses/1039062/lectures/#{id}?fields%5Blecture%5D=view_html"
    headers = ["Authorization": "Bearer #{@token}"]
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(lecture_url, headers)
    %{"view_html" => view_html } = Poison.Parser.parse!(body)
    [src|_] = _sources = Floki.find(view_html,"source")
      |> Enum.map(fn({_, [{_, src},_,{_, hd}], _}) -> {src,hd} end)
      |> Enum.filter(fn({_, hd}) -> hd === "720" end)
      |> Enum.map(fn({src, _}) -> src end)

    IO.inspect src
  end
end
