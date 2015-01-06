require "prawn"
require "yaml"
require "rexml/document"

ARGV.each do |a|
    puts "Argument: #{a}"
end

cfg = begin
    YAML::load(File.open("config.yml"))
rescue ArgumentError => e
    puts "Could not parse YAML: #{e.message}"
    exit
end
puts "Config file succesfully read."


Prawn::Document.generate(cfg["output_name"],
                        :page_size => cfg["page_size"]
    ) do
    font cfg["font"]
    font_size cfg["font_size"]
    text "Hello World! Written in Times. More text to test if wrap is going to work."

    transparent(0.5) { stroke_bounds }

    fill_color "0000FF"
    fill_circle [bounds.left, bounds.top], 30
    fill_circle [bounds.right, bounds.top], 30
    fill_circle [bounds.right, bounds.bottom], 30
    fill_circle [0, 0], 30
end

def test_fonts()
    Prawn::Document.generate("font_test.pdf") do
        font_size 20
        for font_name in Prawn::Font::AFM::BUILT_INS
            font font_name
            text "#{font_name}: The quick brown dog jumped over the lazy fox."
            move_down 10
        end
    end
end
