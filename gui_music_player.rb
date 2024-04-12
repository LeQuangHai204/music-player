require 'gosu'

module ZOrder
  BACKGROUND, PLAYER, UI, TOP, PRIORITY = *0..4
end

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end

GENRE_NAMES = %w[Null Pop Classic Jazz Rock]

class Collection
  attr_reader :albums

  def initialize(music_file)
    @albums = []
    load_albums(music_file)
  end

  def load_albums(album_file)
    album_file = File.new(album_file, 'r')
    no_of_albums = album_file.gets.to_i
    no_of_albums.times do
      album = load_album(album_file)
      @albums << album
    end
    album_file.close
  end

  def load_album(album_file)
    album_title = album_file.gets.chomp
    artist = album_file.gets.chomp
    year = album_file.gets.chomp
    genre = album_file.gets.chomp
    artwork = load_artwork(album_file)
    tracks = load_tracks(album_file)
    Album.new(album_title, artist, year, genre, artwork, tracks)
  end

  def load_artwork(album_file)
    bmp1 = album_file.gets.chomp
    bmp2 = album_file.gets.chomp
    ArtWork.new(bmp1, bmp2)
  end

  def load_tracks(album_file)
    no_of_tracks = album_file.gets.to_i
    tracks = []
    no_of_tracks.times do
      track = load_track(album_file)
      tracks << track
    end
    tracks
  end

  def load_track(album_file)
    track_title = album_file.gets.chomp
    track_location = album_file.gets.chomp
    Track.new(track_title, track_location)
  end

  def sort_latest
    n = @albums.length
    # Traverse through all array elements
    for i in 0...n
      # Find the minimum element in remaining
      min_idx = i
      for j in i + 1...n
        min_idx = j if @albums[j].year < @albums[min_idx].year
      end
      # Swap the found minimum element with the first element
      temp = @albums[min_idx]
      @albums[min_idx] = @albums[i]
      @albums[i] = temp
    end
  end

  def sort_oldest
    n = @albums.length
    # Traverse through all array elements
    for i in 0...n
      # Find the minimum element in remaining
      min_idx = i
      for j in i + 1...n
        min_idx = j if @albums[j].year > @albums[min_idx].year
      end
      # Swap the found minimum element with the first element
      temp = @albums[min_idx]
      @albums[min_idx] = @albums[i]
      @albums[i] = temp
    end
  end
end

class Album
  # attr_accessor :title, :artist, :artwork, :tracks
  def initialize(title, artist, year, genre, artwork, tracks)
    @title = title
    @artist = artist
    @year = year
    @genre = genre
    @artwork = artwork
    @tracks = tracks
  end

  attr_reader :title, :artist, :year, :genre, :artwork, :tracks
end

class Track
  # attr_accessor :title, :location
  def initialize(title, location)
    @title = title
    @location = location
  end

  attr_reader :title, :location

  def play
    @song = Gosu::Song.new(@location)
    @song.play(false)
  end

  def stop
    @song.stop if @song
  end
end

class ArtWork
  def initialize(file1, file2)
    @bmp1 = Gosu::Image.new(file1)
    @bmp2 = Gosu::Image.new(file2)
  end

  attr_reader :bmp1, :bmp2
end

class Button
  def initialize(left, top, right, bottom)
    @left = left
    @right = right
    @top = top
    @bottom = bottom
  end

  attr_reader :left, :right, :top, :bottom

  def width
    @right - @left
  end

  def height
    @bottom - @top
  end
end
# Put your record definitions here

class MusicPlayerMain < Gosu::Window
  def initialize(album_file)
    super 1200, 800, false
    self.caption = 'Music Player'

    @collection = Collection.new(album_file)
    @albums = @collection.albums

    @color = {
      background: Gosu::Color.new(0xFF1EB1FA),
      foreground: Gosu::Color.new(0xFF1D4DB5)
    }

    @show = 'menu' # OR "album"

    @mouse_over_album_in_main = 0
    @mouse_over_track_in_album = 0

    @lastly_displayed_alb = 3
    @font = Gosu::Font.new(29)
    @song = nil
    @selected_album = nil
    @selected_album_no = 0
    @selected_track = nil
    @selected_track_no = 0
    @added_track = nil
    @all_alb = true

    @menu_cord = {
      left: 15,
      right: 480,
      top: 15,
      bottom: 410
    }
    @display = {
      alb_year: false,
      genre_sort_btn: true,
      add_to_playlist: false,
      playlists: false
    }
    @btn = {
      more_alb: Button.new(962, 630, 1188, 680),
      back: Button.new(972, 724, 1196, 792),
      next_alb: Button.new(762, 724, 962, 792),
      latest_alb: Button.new(962, 50, 1188, 100),
      oldest_alb: Button.new(962, 120, 1188, 170),
      genre_sort: Button.new(960, 190, 1190, 240),
      genres: [Button.new(960, 560, 1180, 610),
               Button.new(960, 320, 1180, 370),
               Button.new(960, 380, 1180, 430),
               Button.new(960, 440, 1180, 490),
               Button.new(960, 500, 1180, 550)],
      playlist: Button.new(962, 700, 1188, 750),
      playlists: [Button.new(370, 250, 850, 300),
                  Button.new(370, 320, 850, 370),
                  Button.new(370, 390, 850, 440),
                  Button.new(370, 460, 850, 510)],
      playlist_board: Button.new(300, 200, 900, 600)
    }
    @playlists = Array.new(4)
  end

  # Detects if a 'mouse sensitive' area has been clicked on
  def area_clicked(leftX, topY, rightX, bottomY)
    return true if mouse_x > leftX && mouse_x < rightX && mouse_y > topY && mouse_y < bottomY

    false
  end

  def btn_clicked(btn)
    area_clicked(btn.left, btn.top, btn.right, btn.bottom)
  end

  # Takes a track index and an Album and plays the Track from the Album
  def handle_song
    if @selected_track == @selected_album.tracks[@mouse_over_track_in_album - 1]
      stop_track
    else
      @selected_track_no = @mouse_over_track_in_album
      @selected_track = @selected_album.tracks[@selected_track_no - 1]
      @selected_track.play
    end
  end

  def next_alb
    if @selected_album_no < @albums.length - 1
      @selected_album_no += 1
    else
      @selected_album_no = 0
    end
    @selected_album = @albums[@selected_album_no]
    stop_track
  end

  def stop_track
    @selected_track.stop if @selected_track
    @selected_track = nil
  end

  def mouse_over_album_in_main
    left = 0
    mid_x = @menu_cord[:right]
    right = @menu_cord[:right] * 2

    top = 0
    mid_y = @menu_cord[:bottom] - 10
    bot = @menu_cord[:bottom] * 2

    i = @lastly_displayed_alb
    if area_clicked(left, top, mid_x, mid_y) && @albums[i - 3]
      i - 2
    elsif area_clicked(mid_x, top, right, mid_y) && @albums[i - 2]
      i - 1
    elsif area_clicked(left, mid_y, mid_x, bot) && @albums[i - 1]
      i
    elsif area_clicked(mid_x, mid_y, right, bot) && @albums[i]
      i + 1
    else
      0
    end
  end

  def mouse_over_track_in_album
    track_id = ((mouse_y - 12) / 41).to_i
    return track_id if mouse_x > 830 && track_id > 0 && track_id < @selected_album.tracks.length + 1

    0
  end

  def mouse_over_add_playlist
    y_cord = 25 + 41 * @mouse_over_track_in_album
    area_clicked(900, y_cord, 1100, y_cord + 50)
  end

  def select_playlist
    for i in 0..@btn[:playlists].length - 1
      return i + 1 if btn_clicked(@btn[:playlists][i])
    end
    0
  end

  def sort_genre
    genre = genre_selected
    @display[:genre_sort_btn] = true
    @albums = @collection.albums.clone
    return if genre == 0

    new_collection = []
    @albums.each do |album|
      new_collection << album if album.genre.to_i == genre
    end

    @albums = new_collection
  end

  def sort_latest
    @collection.sort_latest
    @albums = @collection.albums
    @display[:alb_year] = true
  end

  def sort_oldest
    @collection.sort_oldest
    @albums = @collection.albums
    @display[:alb_year] = true
  end

  def genre_selected
    @btn[:genres].index { |btn| btn_clicked(btn) } || -1
  end

  def draw_background
    draw_rect(0, 0, 1200, 800, @color[:background], ZOrder::BACKGROUND)
  end

  def draw_btn_with_title(title, title_color, title_scale, btn_color, btn_stat, z_title = ZOrder::UI,
                          z_btn = ZOrder::BACKGROUND)
    left = btn_stat.left
    top = btn_stat.top
    right = btn_stat.right
    bottom = btn_stat.bottom
    width = btn_stat.width
    height = btn_stat.height

    if area_clicked(left,
                    top, right, bottom)
      draw_rect(left - 2, top - 2, width + 4, height + 4, Gosu::Color::BLACK, z_btn,
                mode = :default)
    end
    draw_rect(left, top, width, height, btn_color, z_btn, mode = :default)

    x_cord = left + width / 2
    y_cord = top + height / 2
    rel_x = 0.5
    rel_y = 0.5
    @font.draw_text_rel(title, x_cord, y_cord, z_title, rel_x, rel_y, title_scale, title_scale, title_color,
                        mode = :default)
  end

  # Not used? Everything depends on mouse actions.
  def update
    case @show
    when 'menu'
      @mouse_over_album_in_main = mouse_over_album_in_main
    when 'album', 'playlist'
      @mouse_over_track_in_album = mouse_over_track_in_album
    end
  end

  # Draws the album images and the track list for the selected album
  def draw
    puts @lastly_displayed_alb

    draw_background
    case @show
    when 'menu'
      draw_menu
    when 'album'
      display_album
    when 'playlist'
      display_album
    end
  end

  def needs_cursor?
    true
  end

  # If the button area (rectangle) has been clicked on change the background color
  def button_down(id)
    case id
    when Gosu::MsLeft
      case @show
      when 'menu'
        process_menu
      when 'album', 'playlist'
        process_album
      end
    when Gosu::MsRight
      case @show
      when 'album'
        if @mouse_over_track_in_album != 0
          @display[:add_to_playlist] = true
          @added_track = @selected_album.tracks[@mouse_over_track_in_album - 1]
        end
      end
    end
  end

  def process_menu
    if btn_clicked(@btn[:playlist])
      @display[:playlists] = true
    elsif btn_clicked(@btn[:more_alb])
      if @lastly_displayed_alb >= @albums.length - 1
        @lastly_displayed_alb = 3
      else
        @lastly_displayed_alb += 1
      end
    elsif @display[:playlists] && !btn_clicked(@btn[:playlist_board])
      @display[:playlists] = false
      @message = nil
    elsif @display[:playlists]
      show_playlists
    elsif @mouse_over_album_in_main != 0
      @show = 'album'
      @selected_album_no = @mouse_over_album_in_main - 1
      @selected_album = @albums[@selected_album_no]
    elsif btn_clicked(@btn[:latest_alb])
      sort_latest
    elsif btn_clicked(@btn[:oldest_alb])
      sort_oldest
    elsif btn_clicked(@btn[:genre_sort])
      @display[:genre_sort_btn] = false
    elsif !@display[:genre_sort_btn]
      sort_genre if genre_selected != -1
    end
  end

  def process_album
    if select_playlist != 0
      add_track(select_playlist)
    elsif @display[:add_to_playlist] && mouse_over_add_playlist
      @display[:playlists] = true
    elsif !@display[:add_to_playlist] && @display[:playlists]
      @display[:playlists] = false
      @message = nil
    elsif @mouse_over_track_in_album != 0
      handle_song
    elsif btn_clicked(@btn[:back])
      @show = 'menu'
      stop_track
    elsif btn_clicked(@btn[:next_alb])
      next_alb_or_del_plist
    end
    @display[:add_to_playlist] = false
    @track_to_add = nil
  end

  # Draws the artwork on the screen for all the albums
  def draw_menu
    i = @lastly_displayed_alb - 3
    draw_album(@menu_cord[:left], @menu_cord[:top], i) if @albums[i]
    draw_album(@menu_cord[:right], @menu_cord[:top], i + 1) if @albums[i + 1]
    draw_album(@menu_cord[:left], @menu_cord[:bottom], i + 2) if @albums[i + 2]
    draw_album(@menu_cord[:right], @menu_cord[:bottom], i + 3) if @albums[i + 3]

    draw_rect(950, 0, 300, 800, @color[:foreground], ZOrder::BACKGROUND, mode = :default)
    draw_btn_with_title('OLDEST', Gosu::Color::BLACK, 1.1, Gosu::Color::GREEN, @btn[:latest_alb])
    draw_btn_with_title('LATEST', Gosu::Color::BLACK, 1.1, Gosu::Color::GREEN, @btn[:oldest_alb])
    draw_btn_with_title('PLAYLISTS', Gosu::Color::BLACK, 1.1, Gosu::Color::AQUA, @btn[:playlist])
    draw_btn_with_title('MORE ==>', Gosu::Color::BLACK, 1.1, Gosu::Color::AQUA, @btn[:more_alb])
    draw_genre_option
    draw_playlist_table if @display[:playlists]
  end

  def draw_album(x_cord, y_cord, alb_id)
    album = @albums[alb_id]

    album_img = album.artwork.bmp1
    album_title = album.title
    album_title += " (#{album.year})" if @display[:alb_year]

    width = 450
    height = 280

    draw_album_border(x_cord, y_cord, width, height) if alb_id + 1 == @mouse_over_album_in_main
    draw_artwork(x_cord, y_cord, album_img, width, height)
    draw_title(x_cord, y_cord, album_title, width, height)
    add_to_plist_opt_on_rightclick
  end

  def draw_artwork(x_cord, y_cord, img, width, height)
    x_ratio = width / img.width.to_f
    y_ratio = height / img.height.to_f
    img.draw(x_cord, y_cord, ZOrder::PLAYER, x_ratio, y_ratio)
  end

  def draw_title(x_cord, y_cord, title, width, height)
    title_x = x_cord + width / 2
    title_y = y_cord + height + 40
    @font.draw_text_rel(title, title_x, title_y, ZOrder::UI, rel_x = 0.5, rel_y = 0.5, scale_x = 1.2, scale_y = 1.2,
                        Gosu::Color::BLACK, mode = :default)
  end

  def draw_album_border(x_cord, y_cord, width, height)
    draw_rect(x_cord - 3, y_cord - 3, width + 6, height + 76, Gosu::Color::YELLOW, ZOrder::BACKGROUND, mode = :default)
    draw_rect(x_cord, y_cord, width, height + 70, @color[:background], ZOrder::BACKGROUND, mode = :default)
  end

  def draw_genre_option
    if @display[:genre_sort_btn]
      draw_btn_with_title('SORT by GENRE', Gosu::Color::BLACK, 1, Gosu::Color::AQUA, @btn[:genre_sort])
      return
    end
    draw_btn_with_title('Which genre to see?', Gosu::Color::WHITE, 1.0, Gosu::Color::BLUE,
                        Button.new(952, 240, 1198, 300))
    draw_btn_with_title('pop', Gosu::Color::BLACK, 1, Gosu::Color::YELLOW, @btn[:genres][1])
    draw_btn_with_title('classic', Gosu::Color::BLACK, 1, Gosu::Color::YELLOW, @btn[:genres][2])
    draw_btn_with_title('jazz', Gosu::Color::BLACK, 1, Gosu::Color::YELLOW, @btn[:genres][3])
    draw_btn_with_title('rock', Gosu::Color::BLACK, 1, Gosu::Color::YELLOW, @btn[:genres][4])
    draw_btn_with_title('all genres', Gosu::Color::BLACK, 1, Gosu::Color::YELLOW, @btn[:genres][0])
  end

  # Move from main to album
  def display_album
    display_artwork
    display_tracks

    highlight_hovered_track
    highlight_playing_track if @selected_track

    if @show == 'album'
      title = 'NEXT ALBUM'
    elsif @show == 'playlist'
      title = 'DELETE LIST'
    end

    draw_btn_with_title('BACK TO MAIN', Gosu::Color::WHITE, 1, @color[:foreground], @btn[:back])
    draw_btn_with_title(title, Gosu::Color::WHITE, 1, @color[:foreground], @btn[:next_alb])
    draw_playlist_table if @display[:playlists]
    add_to_plist_opt_on_rightclick
  end

  def display_artwork
    img = @selected_album.artwork.bmp2
    ratio = 780 / img.width.to_f
    img.draw(x = 30, y = 30, ZOrder::PLAYER, ratio, ratio)

    playing_icon = Gosu::Image.new('images/icon2.png')
    playing_icon.draw(x = 120, y = 400, ZOrder::UI, 1.8, 1.6)
    waves = Gosu::Image.new('images/waves.png')
    waves.draw(x = 0, y = 430, ZOrder::UI, 2.4, 1.6)
  end

  def display_tracks
    tracks = @selected_album.tracks
    ypos = 65

    @font.draw_text('Select Track to Play: ', 850, 18, ZOrder::PLAYER, 1.2, 1.2, Gosu::Color::BLUE)

    tracks.each do |track|
      display_track(track.title, ypos)
      ypos += 41
    end
  end

  def display_track(title, y_pos, color = Gosu::Color::BLACK)
    x_pos = 850
    @font.draw_text(title, x_pos, y_pos, ZOrder::PLAYER, 1.0, 1.0, color)
  end

  def highlight_hovered_track
    return if @mouse_over_track_in_album == 0

    x_cord = 840
    y_cord = 14 + 41 * @mouse_over_track_in_album
    draw_rect(x_cord, y_cord, 320, 47, Gosu::Color::YELLOW, ZOrder::BACKGROUND, mode = :default)
  end

  def highlight_playing_track
    # return if !@selected_track
    x_cord = 840
    y_cord = 14 + 41 * @selected_track_no
    draw_rect(x_cord, y_cord, 320, 47, @color[:foreground], ZOrder::BACKGROUND, mode = :default)
    display_track(@selected_track.title, y_cord + 10, Gosu::Color::WHITE)
  end

  def add_to_plist_opt_on_rightclick
    if @mouse_over_track_in_album != 0 && @display[:add_to_playlist]
      btn = Button.new(900, 25 + 41 * @mouse_over_track_in_album, 1100, 75 + 41 * @mouse_over_track_in_album)
      draw_btn_with_title('add to playlist', Gosu::Color::WHITE, 1, @color[:foreground], btn)
    end
    return unless @message

    @font.draw_text_rel(@message, 600, 550, ZOrder::TOP, 0.5, 0.5, 1.2, 1.2, Gosu::Color::RED)
  end

  def draw_playlist_table
    x_cord = 300
    y_cord = 200
    draw_btn_with_title('', Gosu::Color::AQUA, 1.2, Gosu::Color::AQUA, @btn[:playlist_board], ZOrder::TOP, ZOrder::TOP)
    Gosu::Image.new('images/add_btn.png').draw(x_cord + 10, y_cord + 10, ZOrder::TOP, 0.1, 0.1)

    4.times do |i|
      draw_btn_with_title("playlist #{i + 1}", Gosu::Color::WHITE, 1.2, @color[:background], @btn[:playlists][i],
                          ZOrder::TOP, ZOrder::TOP)
    end
    add_to_plist_opt_on_rightclick
  end

  def add_track(plist_id)
    plist_file = "playlists/playlist#{plist_id}.txt"
    if !File.exist?(plist_file)
      create_playlist(plist_id)
    elsif track_already_added(plist_file)
      @message = 'track already added'
      return
    end
    add_track_to_file(plist_file)
  end

  def add_track_to_file(plist_file)
    return unless @added_track && @show == 'album'

    File.open(plist_file, 'r+') do |file|
      # read the first six lines and store them in variables
      line0 = file.readline
      line1 = file.readline
      line2 = file.readline
      line3 = file.readline
      line4 = file.readline
      line5 = file.readline
      line6 = file.readline

      # read the value on the 7th line and convert it to an integer
      line7 = file.readline
      no_of_tracks = line7.chomp.to_i

      # increment the value and rewrite the 7th line
      no_of_tracks += 1
      line7 = "#{no_of_tracks}\n"

      # read the remaining lines of the file
      lines = file.readlines

      # move the file pointer back to the beginning of the file
      file.rewind

      # write the modified lines back to the file
      file.write(line0)
      file.write(line1)
      file.write(line2)
      file.write(line3)
      file.write(line4)
      file.write(line5)
      file.write(line6)
      file.write(line7)
      file.write(lines.join)
    end

    File.open(plist_file, 'a') do |file|
      file.write(@added_track.title + "\n")
      file.write("#{@added_track.location}\n")
      file.close
    end

    @message = 'successfully add track to playlist'
  end

  def track_already_added(plist_file)
    return unless @added_track

    File.open(plist_file, 'r+') do |file|
      7.times do
        file.readline
      end

      until file.eof?
        current_track = file.readline.chomp
        return true if @added_track.title == current_track
      end

      file.close
    end

    false
  end

  def create_playlist(plist_id)
    File.open("playlists/playlist#{plist_id}.txt", 'w') do |file|
      file.write("1\n")
      file.write("playlist#{plist_id}\n")
      file.write("user\n")
      file.write("2023\n")
      file.write("0\n")
      file.write("images/pic#{plist_id + 8}.png\n")
      file.write("images/pic#{plist_id + 9}.png\n")
      file.write("0\n")
    end
  end

  def show_playlists
    unless File.exist?("playlists/playlist#{select_playlist}.txt")
      @message = 'non-existent playlist'
      return
    end
    collection = Collection.new("playlists/playlist#{select_playlist}.txt")
    @selected_album = collection.albums[0].clone
    @show = 'playlist'
  end

  def next_alb_or_del_plist
    if @show == 'album'
      next_alb
    else # delete the playlist file and back to menu
      File.delete("playlists/#{@selected_album.title}.txt")
      @show = 'menu'
      @selected_album = nil
    end
  end
end

MusicPlayerMain.new('albums.txt').show if __FILE__ == $0
