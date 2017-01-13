defmodule UdemySipper do
  @token "YOUR Authorization Token"

  def go do
    courses = [
      1039062,
      959700
    ]
    courses
    |> Enum.each(&playlist/1)
  end

  def playlist(course_id) do
    File.mkdir_p!("downloads/courses_#{course_id}")
    playlist_url = "https://www.udemy.com/api-2.0/courses/#{course_id}/cached-subscriber-curriculum-items?page_size=9999&fields%5Basset%5D=filename,asset_type"
    %{"results" => results} = fetch_data(playlist_url)
    results
      |> Enum.filter(fn(%{"_class" => class}) -> class === "lecture" end )
      |> Enum.filter(fn(%{"asset" => %{"asset_type" => type}}) -> type === "Video" end)
      |> Enum.map(&map_lecture/1)
      |> Enum.each(fn(lec) -> lecture_detail(lec, course_id) end)
  end

  defp fetch_data(url) do
    headers = ["Authorization": "Bearer #{@token}"]
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, headers)
    Poison.Parser.parse!(body)
  end

  defp map_lecture(%{"id" => id, "asset" => %{"filename" => filename}}) do
    filename = Path.basename(filename, ".mov") <> ".mp4"
    %{id: id, filename: filename}
  end

  defp lecture_detail(%{id: id, filename: filename},course_id) do
    lecture_url = "https://www.udemy.com/api-2.0/users/me/subscribed-courses/#{course_id}/lectures/#{id}?fields%5Blecture%5D=view_html"
    %{"view_html" => view_html } = fetch_data(lecture_url)
    [src|_] = Floki.find(view_html,"source")
      |> Enum.map(fn({_, [{_, src},_,{_, hd}], _}) -> {src,hd} end)
      |> Enum.filter(fn({_, hd}) -> hd === "720" end)
      |> Enum.map(fn({src, _}) -> src end)

    download(src,filename,course_id)
  end

  defp download(src,filename,course_id) do
    IO.puts ">>>>>>>=========================================="
    IO.puts filename
    IO.puts ">>>>>>>=========================================="
    System.cmd("wget", [src,"-c","-O","downloads/courses_#{course_id}/#{filename}"])
  end
end
