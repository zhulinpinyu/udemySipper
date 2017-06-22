defmodule UdemySipper do
  @token "TOKEN"
  @course_id 1075642

  def go do
    # courses = [ 705264 ]
    # courses
    # |> Enum.each(&playlist/1)
    conn = %{course_id: @course_id}
    |> mkdir_course_folder
    |> playlist_url
    |> lectures
    |> fetch_lecture_detail
    |> downloads_video
  end

  def mkdir_course_folder(%{course_id: course_id} = conn) do
    File.mkdir_p!("downloads/courses_#{course_id}")
    conn
  end

  def playlist_url(%{course_id: course_id} = conn) do
    Map.put(conn, :url, "https://www.udemy.com/api-2.0/courses/#{course_id}/cached-subscriber-curriculum-items?page_size=9999&fields%5Basset%5D=filename,asset_type")
  end

  def lectures(%{url: url, course_id: course_id} = conn) do
    %{"results" => results} = fetch_data(url)
    [h|t] = results
      |> Enum.filter(&isLecture/1)
      |> Enum.filter(&isVideo/1)
      |> Enum.with_index()
      |> Enum.map(&thin_lecture/1)
    Map.put(conn, :lectures, [h])
  end

  def fetch_lecture_detail(%{lectures: lectures, course_id: course_id} = conn) do
    ret = lectures
    |> Enum.map(fn(lec) -> lecture_detail(lec, course_id) end)
    %{conn| lectures: ret}
  end

  def downloads_video(%{lectures: lectures, course_id: course_id} = conn) do
    lectures
    |> Enum.each(fn(lec) -> download(lec, course_id) end)
  end

  def isLecture(%{"_class" => class} = lecture) do
    class === "lecture"
  end

  def isVideo(%{"asset" => %{"asset_type" => type}} = lecture) do
    type === "Video"
  end

  defp thin_lecture({%{"id" => id, "title" => title}, index}) do
    %{id: id, filename: "#{(index+1)}.#{title}.mp4"}
  end

  defp lecture_detail(%{id: id} = lecture, course_id) do
    lecture_url = "https://www.udemy.com/api-2.0/users/me/subscribed-courses/#{course_id}/lectures/#{id}?fields%5Blecture%5D=view_html"
    [%{"src" => src}] = lecture_url
      |> fetch_data
      |> view_html
      |> String.replace("\\u0026", "&")
      |> Floki.find("react-video-player")
      |> Floki.attribute("videojs-setup-data")
      |> parseData
      |> Enum.filter(fn(%{"label" => hd }) -> hd === "720" end)

    Map.put(lecture, :src, src)
  end

  def view_html(%{"view_html" => view_html } = lecture) do
    view_html
  end

  def parseData([data]) do
    %{ "sources" => sources } = Poison.Parser.parse!(data)
    sources
  end

  defp fetch_data(url) do
    headers = ["Authorization": "Bearer #{@token}"]
    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, headers)
    Poison.Parser.parse!(body)
  end

  defp download(%{src: src,filename: filename}, course_id) do
    IO.puts "<<------#{filename}------>>"
    IO.puts src
    IO.puts course_id
    #System.cmd("wget", [src,"-c","-O","downloads/courses_#{course_id}/#{filename}"])
  end
end
