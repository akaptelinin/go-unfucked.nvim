package test

import (
	"errors"
	"fmt"
	"log"
)

// ============================================
// SHOULD BE DIMMED (simple returns)
// ============================================

func simpleReturn(err error) error {
	if err != nil {
		return err
	}
	return nil
}

func simpleReturnNil(err error) error {
	if err != nil {
		return nil
	}
	return nil
}

func returnWithValue(err error) (int, error) {
	if err != nil {
		return 0, err
	}
	return 42, nil
}

func returnNamedError(err error) (result int, outErr error) {
	if err != nil {
		return 0, err
	}
	return 42, nil
}

func multipleSimpleReturns(a, b error) error {
	if a != nil {
		return a
	}
	if b != nil {
		return b
	}
	return nil
}

func errEqualNil(err error) error {
	if err == nil {
		return nil
	}
	return err
}

func spacesInCondition(err error) error {
	if err   !=   nil {
		return err
	}
	return nil
}

func returnNewError(err error) error {
	if err != nil {
		return errors.New("something failed")
	}
	return nil
}

// ============================================
// SHOULD BE DIMMED (wrapped returns)
// ============================================

func wrappedFmtErrorf(err error) error {
	if err != nil {
		return fmt.Errorf("wrap: %w", err)
	}
	return nil
}

func wrappedErrorsWrap(err error) error {
	if err != nil {
		return errors.Wrap(err, "context")
	}
	return nil
}

func wrappedWrapf(err error) error {
	if err != nil {
		return errors.Wrapf(err, "context %d", 42)
	}
	return nil
}

func wrappedPkgErrors(err error) error {
	if err != nil {
		return fmt.Errorf("failed to process: %w", err)
	}
	return nil
}

// ============================================
// SHOULD NOT BE DIMMED (side effects)
// ============================================

func withLogger(err error) error {
	if err != nil {
		log.Println("error:", err)
		return err
	}
	return nil
}

func withLoggerError(err error) error {
	if err != nil {
		log.Printf("error: %v", err)
		return err
	}
	return nil
}

func withFmtPrint(err error) error {
	if err != nil {
		fmt.Println("error:", err)
		return err
	}
	return nil
}

func withAssignment(err error) error {
	if err != nil {
		globalErr = err
		return err
	}
	return nil
}

var globalErr error

func withShortVarDecl(err error) error {
	if err != nil {
		msg := err.Error()
		_ = msg
		return err
	}
	return nil
}

func withFunctionCall(err error) error {
	if err != nil {
		notifyError(err)
		return err
	}
	return nil
}

func notifyError(err error) {}

func withDefer(err error) error {
	if err != nil {
		defer cleanup()
		return err
	}
	return nil
}

func cleanup() {}

func withMultipleStatements(err error) error {
	if err != nil {
		log.Println("error")
		notifyError(err)
		return err
	}
	return nil
}

func withMetrics(err error) error {
	if err != nil {
		metrics.Inc("errors")
		return err
	}
	return nil
}

var metrics = struct{ Inc func(string) }{}

func withContextCancel(ctx context.Context, err error) error {
	if err != nil {
		cancel()
		return err
	}
	return nil
}

func cancel() {}

// ============================================
// EDGE CASES - behavior may vary
// ============================================

func nestedIf(err error, flag bool) error {
	if err != nil {
		if flag {
			return err
		}
		return nil
	}
	return nil
}

func ifElse(err error) error {
	if err != nil {
		return err
	} else {
		return nil
	}
}

func switchInside(err error) error {
	if err != nil {
		switch err.Error() {
		case "timeout":
			return err
		default:
			return nil
		}
	}
	return nil
}

func panicInside(err error) error {
	if err != nil {
		panic(err)
	}
	return nil
}

func returnInGoroutine(err error) error {
	if err != nil {
		go func() {
			log.Println(err)
		}()
		return err
	}
	return nil
}

func emptyBlock(err error) error {
	if err != nil {
	}
	return nil
}

func onlyComment(err error) error {
	if err != nil {
		// TODO: handle this
	}
	return nil
}

func breakInLoop(items []string) error {
	for _, item := range items {
		err := process(item)
		if err != nil {
			break
		}
	}
	return nil
}

func continueInLoop(items []string) error {
	for _, item := range items {
		err := process(item)
		if err != nil {
			continue
		}
	}
	return nil
}

func process(s string) error { return nil }

// Different error variable names
func differentErrName(e error) error {
	if e != nil {
		return e
	}
	return nil
}

func customErrName(processError error) error {
	if processError != nil {
		return processError
	}
	return nil
}

// Multiple returns in one block
func multipleReturnsInBlock(err error, flag bool) error {
	if err != nil {
		if flag {
			return err
		}
		return errors.New("default")
	}
	return nil
}

// Return with type conversion
func returnWithConversion(err error) error {
	if err != nil {
		return error(err)
	}
	return nil
}

// Immediately invoked function
func iife(err error) error {
	if err != nil {
		return func() error { return err }()
	}
	return nil
}

// With blank identifier
func withBlankIdentifier(err error) (int, error) {
	if err != nil {
		_ = err.Error()
		return 0, err
	}
	return 1, nil
}

type context struct{}

func (c context) Context() {}
