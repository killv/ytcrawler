import json
import net.http
import os
import rand
import regex

const video_id_filename := 'video_ids.json'
const initial_video_id = 'lU_1_2RIkMc'

fn extract_video_ids(input string) []string {
	mut ids := []string{}
	mut re  := regex.regex_opt(r'"videoId":\s*"([^"]+)","') or { panic(err) }
	matches := re.find_all_str(input)
	// println('| matched with regex  : ${matches.len}')

	for s in matches {
		value := s[11..22]
		// println(value in ids)

		if !(value in ids) {
			ids << value
		}
	}

	return ids
}

fn save_html(content string) {
	filename := "youtube.html"
	// Write the string to the file
	os.write_file(filename, content) or {
		println("Failed to save HTML: $err")
		return
	}

	println("HTML saved successfully!")
	return
}

fn save_video_ids(video_ids []string) {
	// video_id_filename := 'video_ids.json'
	println('| save_video_ids      : ${video_ids.len}')
	encoded := json.encode(video_ids)

	os.write_file(video_id_filename, encoded) or {
		println("Failed to save video_ids: $err")
		return
	}

	println('|___________________________________')
	println('|\n| video_ids saved successfully!')
	println('|___________________________________')
	return
}

fn get_page(url string) string {
	// http.fetch() sends an HTTP request to the URL with the given method and configurations.
	config := http.FetchConfig{
		user_agent: 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0'
	}
	println('|   get page')

	resp := http.fetch(http.FetchConfig{ ...config, url: url }) or {
		fetch_err := 'failed to fetch data from the server'
		println(fetch_err)
		return ''
	}

	return resp.body
}

fn get_video_id() string {
	// COV_AtV-1C0
	saved := get_saved_ids()
	index := saved.len - 1
	random_index := rand.intn(saved.len) or { index }
	video_id     := saved[random_index]
	println('| new id              : ${video_id}')

	return video_id
}

fn get_url() string {
	video_id := get_video_id()

	return 'https://www.youtube.com/watch?v=$video_id'
}

fn get_saved_ids() []string {
	// read video_ids.json
	// return video_ids
	// video_id_filename := 'video_ids.json'
	content := os.read_file(video_id_filename) or {
		eprintln('|   Failed to read file: $err')
		return [' ']
	}
	// println('content:')
	// println(content)
	// println(content.len)
	
	decoded := json.decode([]string, content) or {
		eprintln('|   Failed to parse JSON: $err')
		// means storage file is empty
		return [initial_video_id]
	}

	// println('decoded')
	// println(decoded)
	// println(decoded.len)
	
	return decoded
}

fn add_to_data(video_ids []string) bool {
	println('|   add to data')
	// get data from file
	mut saved_video_ids := get_saved_ids()
	mut has_new_id := false
	start_len := saved_video_ids.len
	println('| saved video_ids     : ${start_len}')

	if (start_len == 1) && (saved_video_ids[0] == ' ') {
		println('empty saved')
		saved_video_ids = video_ids.clone()
	}

	for id in video_ids {
		if !(id in saved_video_ids) {
			// println('add id: ${id} in saved')
			saved_video_ids << id
			has_new_id = true
		}
	}

	if has_new_id {
		added := saved_video_ids.len - start_len
		println('| found new video ids : ${added}')
		save_result(saved_video_ids)
	}

	return has_new_id
}

fn loop(number int) {
	max_number := 1000
	println('\n ___________________________________')
	println('|')
	println('| loop number         : $number/${max_number}')

	url  := get_url()
	page := get_page(url)

	if page.len == 0 {
		//  failed to fetch data from the server
		println('no data in response')
		return
	}
	// save html to research
	// save_html(resp.body)

	video_ids := extract_video_ids(page)
	println('| found video ids     : ${video_ids.len}')
	// println(video_ids)
	result := add_to_data(video_ids)

	if !result {
		println('   no new video_ids')
	}

	if number < max_number {
		loop(number + 1)
	}

	return
}

fn prepare() {
	if !os.exists(video_id_filename) {
		os.create(video_id_filename) or {
			println('Error: $err')
			return
		}
	}
}

fn save_result(data []string) {
	println('|   save result')
	save_video_ids(data)
}

fn main() {
	prepare()
	loop(0)
}

