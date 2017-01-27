#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>    // coreモジュールのヘッダーをインクルード
#include <opencv2/highgui.hpp> // highguiモジュールのヘッダーをインクルード
#include <opencv2/imgproc/imgproc.hpp>

#include <fstream>
#include <iostream>
#include <iomanip>
#include <vector>
#include <string>
#include <sstream>
#include <bitset>

using namespace cv;
using namespace std;

//stringにsplitない
vector<string> split(const string &str, char sep)
{
	vector<string> v;
	stringstream ss(str);
	string buffer;
	while (getline(ss, buffer, sep)) {
		v.push_back(buffer);
	}
	return v;
}

map<int,Mat> loadHexFont(){
	ifstream ifs("font.hex");
	string line;
	if (ifs.fail())
	{
		cerr << "file open fail" << endl;
		exit(EXIT_FAILURE);
	}

	map<int, Mat> hexFont;
	Mat glyph(Size(8, 16), CV_8U, Scalar::all(0));

	while (getline(ifs, line))
	{
		bitset<8> glyph_line;
		vector<string> data = split(line, ':');
		//1byte文字だけロードする(めんどいので
		if (data[1].length() != 32 || data[0].length() != 4) continue;
		for (int i = 0; i < 32; i = i + 2){
			glyph_line = stoi(data[1].substr(i, 2), nullptr, 16);
			for (int j = 0; j < 8; j++){
				glyph.at<uchar>(i / 2, j) = glyph_line[7 - j] ? 255 : 0;
			}
		}
		hexFont[stoi(data[0], nullptr, 16)] = glyph.clone();
	}
	return hexFont;
}

int computeBestMatchCharacter(map<int,Mat> hexFont ,Mat c){
	int best_value = INT_MIN;
	int best_char;
	int value;
	
	for (auto itr = hexFont.begin(); itr != hexFont.end(); ++itr){
		value = 0;
		for (int j = 0; j < c.rows; j++){
			for (int i = 0; i < c.cols; i++){
				if ((itr->second).at<uchar>(j, i) == c.at<uchar>(j, i) ){
					value++;	
				}
				else{
					value--;
				}
			}
		}
		if (value > best_value){
			best_value = value;
			best_char = itr->first;
		}
	}
	//応急処置・・・
	if (best_char == 0x0000)
		best_char = 0x0020;

	return best_char;
}

void export(map<int, vector<int>> bigFont, int size){
	ofstream ofs("bigfont-size" + to_string(size));
		
	for (auto itr = bigFont.begin(); itr != bigFont.end(); ++itr){
		ofs << setfill('0') << setw(4) << hex << itr->first << ':';
		for (auto vitr = (itr->second).begin(); vitr != (itr->second).end(); ++vitr){
			ofs << setfill('0') << setw(4) << hex << *vitr;
		}
		ofs << endl;
	}

	ofs.close();
}

int main(int argc, const char* argv[])
{
	map<int,Mat> hexFont = loadHexFont();

	for (int size = 2; size < 9; size++){
		map<int, vector<int>> bigFont;
		//全文字やると時間がかかりすぎるのでとりあえず0x0020~0x007Eまで
		for (int i = 0x0020; i < 0x007F; i++){
			Mat big = hexFont[i].clone();
			resize(big, big, Size(8 * size, 16 * size), INTER_AREA);
			//グレースケールなので二値化しないと0,255以外の値がでる
			cv::threshold(big, big, 0, 255, THRESH_BINARY | THRESH_OTSU);
			for (int y = 0; y < size; y++){
				for (int x = 0; x < size; x++){
					//OC上で一文字分だけ切り取る
					Mat c(big, Rect(x * 8, y * 16, 8, 16));
					cv::threshold(c, c, 0, 255, THRESH_BINARY | THRESH_OTSU);
					bigFont[i].push_back(computeBestMatchCharacter(hexFont, c));
				}
			}
		}
		export(bigFont, size);
	}
	return 0;
}
