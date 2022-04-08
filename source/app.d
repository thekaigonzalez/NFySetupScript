extern (C) int system(const char*);

import std.stdio;
import std.net.curl;
import colorize;
import std.file: read, exists, mkdir;
import std.string;
import std.process;
import std.zip;
import std.json;
import std.conv;
import std.algorithm;
import std.array;

void print_usage(char err='n', string msg="") {
	writeln("usage: nfy-get <NFy|NFyJS|NFyMono|LibNFy>");
	if (err=='-') write ("error: " ~ msg);
	
}

void logMessage(string msg) {
	writeln(("-> " ~ msg).color("blue"));
}

void errorMessage(string msg) {
	writeln(("! " ~ msg).color("red"));
}

void successMessage(string msg) {
	writeln(("> " ~ msg).color("green"));
}

void postMSG(string msg) {
	writeln(("* " ~ msg).color("light_white"));
}

void HintMSG(string msg) {
	writeln(("* " ~ msg).color("yellow"));
}

void DownloadFile(string url, string f) {
	download(url, f);
}

void Extract(string fname, string outputdir) {
	logMessage("Extracting " ~ fname ~ "...");
	auto zip = new ZipArchive(read(fname));
	foreach (ArchiveMember am; zip.directory)
		{
			try {
				// exclude system dirs
			if (startsWith(am.name, "playlists")) continue;
			if (startsWith(am.name, "songs")) continue;
			if (startsWith(am.name, "docs")) continue;
			if (startsWith(am.name, "Linux")) continue;
			
			zip.expand(am);
			logMessage("EXTRACT - " ~ am.name);
			
			auto data = cast(string)am.expandedData();
			File d = File(outputdir ~ "/" ~ am.name, "wb");
			d.write(data);
			d.close();
			} catch (Exception e) {
				errorMessage("Failed to extract " ~ am.name);
			}
		}
}

void MakeIfnot(string dir) {
	if (!exists(dir)) {
			mkdir(dir);
		}
}

int main(string[] args) {
	string nfy = "NFy";
	string[string] dict;
	string[] args2 = args.remove(0);
	foreach (string l ; args2) {
		if (l == "-h") {
			print_usage();
		} else {
			string[] ar = split(l, "=");
			if (ar.length < 2 && ar.length == 1) {
				print_usage('-', "Missing second side of variable");
			}
			dict[ar[0]] = ar[1];
		}
	}

	if (!("version" in dict)) {
		errorMessage("nfy-get requires a version to install!");
		version(Windows) {
			File error = File("error.txt", "w");
			error.write("Nfy-get's syntax is: nfy-get version=NFY_VERSION OPTS...\nyou need to run NFy-get through the command line, preferrably through Windows Terminal.\nWhat you need to do, is open Windows Terminal/Any terminal emulator, go to the directory NFy-get is in.\nThen you run nfy-get using\n.\\nfy-get.exe | .\\nfy-get version=NFy (or your choice of version");
			error.close();
			system("notepad.exe error.txt");
			remove("error.txt");
		}
		return 1;
	}
	logMessage("Gathering NFy...");
	logMessage("getting files...");
	
	if (dict["version"] == "NFyJS") {
		version(Windows) {
			string weburl = "https://github.com/Cliometric/NFY/releases/download/0.0.1/NFyJS.Setup.0.0.1.exe";

			logMessage("Downloading - " ~ weburl);

			
			logMessage("Running NFyJS.setup.exe");

			DownloadFile(weburl, "NFyJS.setup.exe");

			int code = system(cast(const char*)"NFyJS.setup.exe");

			if (code == 0) {
				successMessage("NFy.js installation completed!");
			} else {
				errorMessage("Failed to download NFy.js, NFyJS.setup.exe returned non-exit code 0.");
				return 1;
			}

			logMessage("removing NFyJS.setup.exe");

			try {
				remove("NFyJS.setup.exe");
			} catch (Exception) {
				errorMessage("An exception occurred while trying to remove NFy setup.");
				errorMessage("Make sure there are no processes using NFy.setup.exe.");
				return 1;
			}

		} else {
			errorMessage("No other OSes are supported for NFy.js currently.");
			return 1;
		}
	} else if (dict["version"] == "NFy-Mono") {
		logMessage("Getting NFy Mono...");
		string weburl = "https://github.com/thekaigonzalez/NFyMono/releases/download/version.5/NFyMono5.zip";

		DownloadFile(weburl, "njmono-cache.zip");

	
		logMessage("Creating NfyMono folder...");
		if (!exists("NFyMono")) {
			mkdir("NFyMono");
		}
		if (!exists("NFyMono/songs")) {
			mkdir("NFyMono/songs");
		}
		if (!exists("NFyMono/playlists")) {
			mkdir("NFyMono/playlists");
		}

		logMessage("Extracting NFyMono...");

		Extract("njmono-cache.zip", "NFyMono");

		logMessage("Testing...");

		try {
		auto njunit = execute(["NFyMono/njmono.exe"]);
		} catch (Exception e) {
			errorMessage("Failed to test NJMono - unknown error.");
		}

		postMSG("removing njmono-cache.zip");

		remove("njmono-cache.zip");
		
		successMessage("Test complete!");
		successMessage("NFy Mono files are located in ./NFyMono/.");

	} else if (dict["version"] == "NFy") {
		logMessage("Downloading NFy...");
		string weburl = "https://github.com/thekaigonzalez/NFy/releases/download/0.0.6/NFy_0.6.zip";

		DownloadFile(weburl, "NFylts.zip");

		logMessage("Extracing NFy (this may take a while!)");

		if (!exists("NFy-Latest")) {
			mkdir("NFy-Latest");
		}

		Extract("NFylts.zip", "NFy-Latest");

		HintMSG("Next steps: Add songs from the song index @ https://thekaigonzalez.github.io/NFy!");

		postMSG("creating songs/ & playlists/");

		MakeIfnot("NFy-latest/songs");
		MakeIfnot("NFy-latest/playlists");

		successMessage("NFy Installation Successful!\nFiles can be found in ./NFy-latest!");
	}
	return 0;
}