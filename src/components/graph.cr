def render_graph(values : Array(Number))
  min = values.min
  max = values.max

  result = String.build do |str|
    (0..max).step(by: 2).to_a.reverse.each do |threshold|
      values.each do |value|
        if value > threshold
          if value > threshold + 1
            str << "█"
          else
            str << "▄"
          end
        else
          if threshold == 0 && value == 0
            str << "_"
          else
            str << " "
          end
        end
      end
      str << "\r\n"
    end

    if min < 0
      (0..-min).step(by: 2).each do |threshold|
        values.each do |value|
          if value < -threshold
            if value < -threshold - 1
              str << "█"
            else
              str << "▀"
            end
          else
            str << " "
          end
        end
        str << "\r\n"
      end
    end
  end

  result
end

# str << "                                      ▄\r\n" 6
# str << "                        ▄ ▄         ▄██\r\n" 4
# str << "                    ▄ ▄█████▄█▄   ▄████\r\n" 2
# str << "▄█▄_▄█▄█▄___▄_____▄█████████████▄██████\r\n" 0
# str << "          ▀   ▀█▀                      \r\n" -2
