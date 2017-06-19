defmodule UdemySipper do
  @token "BASIC_TOKEN"

  def go do
    courses = [ 1075642 ]
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
      |> Enum.with_index()
      |> Enum.map(&map_lecture/1)
      |> Enum.each(fn(lec) -> lecture_detail(lec, course_id) end)
  end

  defp fetch_data(url) do
    headers = ["Authorization": "Bearer #{@token}"]
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, headers)
    Poison.Parser.parse!(body)
  end

  defp map_lecture({%{"id" => id, "title" => title}, index}) do
    #filename = Path.basename(filename, ".mov") <> ".mp4"
    filename =  "#{(index+1)}.#{title}.mp4"
    %{id: id, filename: filename}
  end

  defp lecture_detail(%{id: id, filename: filename},course_id) do
    IO.puts filename
    lecture_url = "https://www.udemy.com/api-2.0/users/me/subscribed-courses/#{course_id}/lectures/#{id}?fields%5Blecture%5D=view_html"
    %{"view_html" => view_html } = fetch_data(lecture_url)
    [data] = String.replace(view_html, "\\u0026", "&")
      |> Floki.find("react-video-player")
      |> Floki.attribute("videojs-setup-data")

    %{ "sources" => sources } = Poison.Parser.parse!(data)
    [%{"src" => src}] = sources
      |> Enum.filter(fn(%{"label" => hd }) -> hd === "720" end)

    #download(src,filename,course_id)
  end

  defp download(src,filename,course_id) do
    IO.puts ">>>>>>>=========================================="
    IO.puts filename
    IO.puts ">>>>>>>=========================================="
    System.cmd("wget", [src,"-c","-O","downloads/courses_#{course_id}/#{filename}"])
  end
end
