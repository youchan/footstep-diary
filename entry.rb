HEADER_PARAM = /\s*[\w.]+=(?:[\w.]+|"(?:[^"\\]|\\.)*")?\s*/

p "*/*".scan(HEADER_PARAM)

def test(entry)
  params = entry.scan(HEADER_PARAM).map! do |s|
    key, value = s.strip.split('=', 2)
    value = value[1..-2].gsub(/\\(.)/, '\1') if value.start_with?('"')
    [key, value]
  end

  @entry  = entry
  @type   = entry[/[^;]+/].delete(' ')
  @params = Hash[params]
  @q      = @params.delete('q') { 1.0 }.to_f
end

test("*/*")
