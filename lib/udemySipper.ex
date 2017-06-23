defmodule UdemySipper do
  @token "TOKEN"
  @course_id 1075642

  def go do
    %{id: @course_id, path: "", url: "", lectures: []}
    |> setup
    |> lectures
    |> lectures_detail
    |> downloads_video
  end

  def setup(%{id: id} = course) do
    path = "downloads/courses_#{id}"
    File.mkdir_p!(path)
    url = "https://www.udemy.com/api-2.0/courses/#{id}/cached-subscriber-curriculum-items?page_size=9999&fields%5Basset%5D=filename,asset_type"
    %{course| path: path, url: url}
  end

  def lectures(%{url: url, id: id} = course) do
    [h|_] = fetch_data(url)
      |> Enum.filter(&isLecture/1)
      |> Enum.filter(&isVideo/1)
      |> Enum.with_index()
      |> Enum.map(fn({lecture, index}) -> setup_lecture(%{lecture: lecture, course_id: id, index: index}) end)
    %{course | lectures: [h]}
  end

  def lectures_detail(%{lectures: lectures} = course)do
    %{course | lectures: Enum.map(lectures, &lecture_detail/1)}
  end

  def downloads_video(%{lectures: lectures, path: path}) do
    Enum.each(lectures, fn(lecture) -> download(lecture, path) end)
  end

  def isLecture(%{"_class" => class}) do
    class === "lecture"
  end

  def isVideo(%{"asset" => %{"asset_type" => type}}) do
    type === "Video"
  end

  defp setup_lecture(%{lecture: %{"id" => id, "title" => title}, course_id: course_id, index: index}) do
    %{id: id, filename: "#{(index+1)}.#{title}.mp4", url: "https://www.udemy.com/api-2.0/users/me/subscribed-courses/#{course_id}/lectures/#{id}?fields%5Blecture%5D=view_html"}
  end

  defp lecture_detail(%{url: url} = lecture) do
    %{"src" => src} = fetch_data(url)
      |> String.replace("\\u0026", "&")
      |> Floki.find("react-video-player")
      |> Floki.attribute("videojs-setup-data")
      |> List.first
      |> parseData
      |> Enum.filter(fn(%{"label" => hd }) -> hd === "720" end)
      |> List.first
    Map.put(lecture, :src, src)
  end

  defp fetch_data(url) do
    headers = ["Authorization": "Bearer #{@token}"]
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, headers)
    parseData(body)
  end

  defp parseData(data) do
    case Poison.Parser.parse!(data) do
      %{"results" => results} ->
        results
      %{"view_html" => view_html } ->
        view_html
      %{ "sources" => sources } ->
        sources
    end
  end

  defp download(%{src: src, filename: filename}, path) do
    IO.puts "<<------#{filename}------>>"
    IO.puts src
    IO.puts path
    #System.cmd("wget", [src,"-c","-O","#{path}/#{filename}"])
  end
end
