require "prawn"
require "yaml"
require "rexml/document"
require "net/http"
require_relative "borders"

def main()
	cfg_file = begin
		File.open("config.yml")
	rescue
		print "ERROR: config.yml not found, exiting."
		exit
	end

	cfg = begin
		YAML::load(cfg_file)
	rescue ArgumentError => e
		puts "Could not parse YAML: #{e.message}"
		exit
	end

	puts "Config file succesfully read."

    create_thankyou(cfg)
end

def gen_body_text(cfg)
    body_text = ""

    phrase_blocks = cfg["phrases"]
    # An arbitrary number of blocks are given by the user
    phrase_blocks.each do |block_name, phrases|
        puts "Choosing a phrase from #{block_name}."

        # The phrases can contain substrings of the form %name%, which
        # refer to the values of other variables in the config file.
        # Replace all these with the value they refer to.
        phrase = phrases.sample.gsub(/%[a-zA-Z_0-9]+%/) do |match|
            cfg[match.tr("/%/", "")] # Strip away the '%' signs
        end

        puts "Phrase chosen: '#{phrase}'"
        body_text += phrase + " "
    end

	return body_text
end

def create_thankyou(cfg)
	pdf = Prawn::Document.new( :page_size => cfg["page_size"] )

	pdf.font cfg["font"]
	pdf.font_size cfg["font_size"]

    # Generating text
    recipient = cfg["recipient"]
    greeting = "Dear #{recipient},"

    body = gen_body_text(cfg)

    name = cfg["name"]
    include_kisses = cfg["include_kisses"]
    ending = "Lots of love from #{name}"
    if include_kisses then ending += "\nxxx" end

    block_spacing = cfg["block_spacing"]
	padding = cfg["text_padding"]

    # Calculating text box size
    total_text_height =
        pdf.height_of(greeting) +
        pdf.height_of(body) +
        pdf.height_of(ending) +
        2 * block_spacing

    text_top_bound =
        (pdf.bounds.top - pdf.bounds.bottom) / 2 +
        0.5 * total_text_height 

    text_left_bound =
        pdf.bounds.left + padding

	text_box_width = pdf.bounds.right - pdf.bounds.left - 2 * padding
	text_box_height = pdf.bounds.top - pdf.bounds.bottom - 2 * padding
    
    puts "total_text_height: #{total_text_height}"
    puts "text_top_bound: #{text_top_bound}"


	# Create the bounding box where text will go 
	pdf.bounding_box(
		[text_left_bound,
         text_top_bound],
		:width => text_box_width,
		:height => text_box_height) do

		pdf.text greeting, :align => :left
        pdf.move_down block_spacing
		pdf.text body, :align => :center
        pdf.move_down block_spacing
        pdf.text ending, :align => :center
	end

	pdf.transparent(0.5) do
		pdf.stroke_bounds
	end

	if cfg["border_style"] == "circles"
		palette_id = cfg["colour_lovers_palette_id"]
		border_circles(pdf, palette_id)
	end

    output_name = cfg["output_name"]
    puts "Saved pdf file as #{output_name}."
	pdf.render_file output_name
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

main()
