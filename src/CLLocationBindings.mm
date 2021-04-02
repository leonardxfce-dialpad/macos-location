#include <math.h>
#include <nan.h>

#import "LocationManager.h"

void getCurrentPosition(const Nan::FunctionCallbackInfo<v8::Value>& args) {
	v8::Isolate* isolate = args.GetIsolate();

	LocationManager* locationManager = [[LocationManager alloc] init];

	v8::Local<v8::Context> context = v8::Context::New(isolate);

	if (args.Length() == 1) {
		if (args[0]->IsObject()) {
			v8::Local<v8::Object> options = args[0]->ToObject(context).ToLocalChecked();

			v8::Local<v8::String> maximumAgeKey = v8::String::NewFromUtf8(isolate, "maximumAge").ToLocalChecked();
			if (options->Has(context, maximumAgeKey).FromMaybe(false)) {
				// Anything less than 100ms doesn't make any sense
				locationManager.maximumAge = fmax(
					100,
					Nan::To<double>(Nan::Get(options, maximumAgeKey).ToLocalChecked()).FromJust()
				);
				locationManager.maximumAge /= 1000.0;
			}

			v8::Local<v8::String> enableHighAccuracyKey = v8::String::NewFromUtf8(
				isolate, 
				"enableHighAccuracy"
			).ToLocalChecked();
			if (options->Has(context, enableHighAccuracyKey).FromMaybe(false)) {
				locationManager.enableHighAccuracy = Nan::To<bool>(Nan::Get(options, enableHighAccuracyKey).ToLocalChecked()).FromJust();
			}

			v8::Local<v8::String> timeout = v8::String::NewFromUtf8(isolate, "timeout").ToLocalChecked();
			if (options->Has(context, timeout).FromMaybe(false)) {
				locationManager.timeout = Nan::To<uint32_t>(Nan::Get(options, timeout).ToLocalChecked()).FromJust();
			}
		}
	}

	if (![CLLocationManager locationServicesEnabled]) {
		isolate->ThrowException(
			Exception::TypeError(
				v8::String::NewFromUtf8(isolate, "CLocationErrorNoLocationService").ToLocalChecked()
			)
		);
		return;
	}

	CLLocation* location = [locationManager getCurrentLocation];

	if ([locationManager hasFailed]) {
		switch (locationManager.errorCode) {
			case kCLErrorDenied:
				isolate->ThrowException(
					Exception::TypeError(
						v8::String::NewFromUtf8(
							isolate,
							"CLocationErrorLocationServiceDenied"
						).ToLocalChecked()
					)
				);
				return;
			case kCLErrorGeocodeCanceled:
				isolate->ThrowException(
					Exception::TypeError(
						v8::String::NewFromUtf8(isolate, "CLocationErrorGeocodeCanceled").ToLocalChecked()
					)
				);
				return;
			case kCLErrorLocationUnknown:
				isolate->ThrowException(
					Exception::TypeError(
						v8::String::NewFromUtf8(isolate, "CLocationErrorLocationUnknown").ToLocalChecked()
					)
				);
				return;
			default:
				isolate->ThrowException(
					Exception::TypeError(
						v8::String::NewFromUtf8(isolate, "CLocationErrorLookupFailed").ToLocalChecked()
					)
				);
				return;
		}
	}

	v8::Local<v8::Object> obj = v8::Object::New(isolate);
	Nan::Set(
		obj,
		v8::String::NewFromUtf8(isolate, "latitude").ToLocalChecked(),
		v8::Number::New(isolate, location.coordinate.latitude)
	);
	Nan::Set(
		obj,
		v8::String::NewFromUtf8(isolate, "longitude").ToLocalChecked(),
		v8::Number::New(isolate, location.coordinate.longitude)
	);
	Nan::Set(
		obj,
		v8::String::NewFromUtf8(isolate, "altitude").ToLocalChecked(),
		v8::Number::New(isolate, location.altitude)
	);
	Nan::Set(
		obj,
		v8::String::NewFromUtf8(isolate, "horizontalAccuracy").ToLocalChecked(),
		v8::Number::New(isolate, location.horizontalAccuracy)
	);
	Nan::Set(
		obj,
		v8::String::NewFromUtf8(isolate, "verticalAccuracy").ToLocalChecked(),
		Number::New(isolate, location.verticalAccuracy)
	);

	NSTimeInterval seconds = [location.timestamp timeIntervalSince1970];
	Nan::Set(
		obj,
		v8::String::NewFromUtf8(isolate, "timestamp").ToLocalChecked(),
		Number::New(isolate, (NSInteger)ceil(seconds * 1000))
	);

	args.GetReturnValue().Set(obj);
}

void Initialise(v8::Local<v8::Object> exports) {
	v8::Local<v8::Context> context = exports->CreationContext();
	exports->Set(
		context,
		Nan::New("getCurrentPosition").ToLocalChecked(),
		Nan::New<v8::FunctionTemplate>(getCurrentPosition)->GetFunction(context).ToLocalChecked()
	);
}

NODE_MODULE(macos_clocation_wrapper, Initialise)