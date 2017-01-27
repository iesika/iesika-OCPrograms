#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/opencv.hpp>

#include <iostream>
#include <fstream>
#include <cmath>
#include <iomanip>   

//unicode2800番からのオフセットを返す
unsigned char getCharCode(cv::Mat oneChar, int res_char_height, int res_char_width);

int main(int argc, const char* argv[]){
	//一文字で表現できる解像度
	int res_char_width = 2;
	int res_char_height = 4;

	//ブロック字のフォントを利用して以下改造度を実現する
	int OC_width = 320;
	int OC_height = 200;

	cv::Mat frame;
	bool isDebug = false;
	bool isLoad = true;

	unsigned char code;

	std::vector<std::string> arguments(argv, argv + argc);
	std::vector<std::string> targetList;

	for (std::string& s : arguments) {
		std::string::size_type pos = s.find_last_of('.');
		if (s.substr(pos + 1) == "mp4") {
			targetList.push_back(s);
			std::cout << "target : " << s << std::endl;
		} else if (s == "--debug") {
			isDebug = false;
		}
	}

	//動画1フレーム用
	cv::namedWindow("frame", cv::WINDOW_AUTOSIZE);

	if (targetList.empty()){
		std::cout << "No input specified" << std::endl;
	} else {
		for (auto target:targetList){
			cv::VideoCapture video(target);
			if (!video.isOpened()) {
				std::cout << "load failure :" << target << std::endl;
				continue;
			}
			std::cout << "load : " << target << std::endl;
			std::ofstream fout("out.ocm1", std::ios::binary);
			fout.write("ocm1", sizeof("ocm1"));
			if (!fout) {
				std::cout << "test.ocm cant open";
				return 1;
			}
			unsigned char pre_char_code = 0x00;
			unsigned char char_code = 0x00;
			unsigned char dupe = 0x00;
			bool isFirst = true;
			while (video.read(frame)){
				//アス比?知らない子ですね・・・
				cv::resize(frame, frame, cv::Size(OC_width, OC_height), cv::INTER_CUBIC);
				cv::cvtColor(frame, frame, cv::COLOR_BGR2GRAY);
				cv::threshold(frame, frame, 0, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);
				if (isDebug){
					cv::imshow("frame", frame);
					cv::waitKey(1);
				}
				for (int height = 0; height < OC_height; height = height + res_char_height){
					for (int width = 0; width < OC_width; width = width + res_char_width){
						//一文字ずつ処理する
						cv::Mat roi(frame, cv::Rect(width, height, res_char_width, res_char_height));
						char_code = getCharCode(roi, res_char_height, res_char_width);
						if (isFirst){
							isFirst = false;
							pre_char_code = char_code;
							continue;
						}
						else if ((width == 0 && height == 0) || char_code != pre_char_code || dupe == 0xFF || width == 0){
							fout.write(reinterpret_cast<char*>(&pre_char_code), sizeof(pre_char_code));
							fout.write(reinterpret_cast<char*>(&dupe), sizeof(dupe));						
							dupe = 0x00;
							pre_char_code = char_code;
							continue;
						}
						if (isDebug){
							std::printf("width : %d  height : %d dupe : %x\n", width, height, dupe);
							cv::waitKey(0);
						}
						pre_char_code = char_code;
						dupe++;				
					}
				}

			}
			fout.write(reinterpret_cast<char*>(&char_code), sizeof(char_code));
			fout.write(reinterpret_cast<char*>(&dupe), sizeof(dupe));
			fout.close();
		}
	}
	return 0;
}

unsigned char getCharCode(cv::Mat oneChar,int res_char_height,int res_char_width){
	int bit = 0;
	unsigned char code = 0x00;
	for (int char_width = 0; char_width < res_char_width; char_width++){
		for (int char_height = 0; char_height < (res_char_height - 1); char_height++){
			if (oneChar.at<uchar>(char_height, char_width) == 255){
				code = code + (unsigned char)std::pow(2, bit);
			}
			bit++;
		}
	}
	if (oneChar.at<uchar>(3, 0) == 255){
		code = code + 0x40;
	}
	if (oneChar.at<uchar>(3, 1) == 255){
		code = code + 0x80;
	}
	return code;
}