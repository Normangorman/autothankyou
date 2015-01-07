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
end

def gen_body_text(cfg)
	name = cfg["name"]
	gift = cfg["gift_received"]
	thankyou_for_gift_phrases = cfg["thankyou_for_gift_phrases"]
	generic_thankyou_phrases = cfg["generic_thankyou_phrases"]
	goodwill_phrases = cfg["goodwill_phrases"]

	text = thankyou_for_gift_phrases.sample.gsub("%GIFT%", gift) + " " + 
		   generic_thankyou_phrases.sample + " " + 
		   goodwill_phrases.sample
	return text
end

def create_thankyou(cfg)
	pdf = Prawn::Document.new( :page_size => cfg["page_size"] )

	pdf.font cfg["font"]
	pdf.font_size cfg["font_size"]

	padding = cfg["text_padding"]
	text_box_width = pdf.bounds.right - pdf.bounds.left - 2 * padding
	text_box_height = pdf.bounds.top - pdf.bounds.bottom - 2 * padding

	# Create the main text box where writing will go
	pdf.bounding_box(
		[pdf.bounds.left + padding, pdf.bounds.top - padding],
		:width => text_box_width,
		:height => text_box_height) do

		block_spacing = cfg["block_spacing"]

		#GREETING
		recipient = cfg["recipient"]
		pdf.text "Dear #{recipient},", :align => :left
		pdf.move_down block_spacing

		#BODY
		gift = cfg["gift_received"]
		pdf.text gen_body_text(cfg), :align => :center
		pdf.move_down block_spacing

		#ENDING
		name = cfg["name"]
		include_kisses = cfg["include_kisses"]
		
		msg = "Lots of love from #{name}"
		if include_kisses then msg += " xxx" end

		pdf.text msg, :align => :center
	end


	pdf.transparent(0.5) do
		pdf.stroke_bounds
	end

	if cfg["border_style"] == "circles"
		palette_id = cfg["colour_lovers_palette_id"]
		border_circles(pdf, palette_id)
	end

	pdf.render_file cfg["output_name"]
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
