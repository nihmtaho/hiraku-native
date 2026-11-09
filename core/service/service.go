// Package service is the only place that coordinates store writes per use case.
package service

import (
	"context"
	"errors"

	"google.golang.org/protobuf/proto"

	"hiraku/core/domain/notetype"
	"hiraku/core/store"

	hirakuv1 "hiraku/core/gen/hirakuv1"
)

// Service handles contract methods against one open store.
type Service struct {
	repo *store.Repo
}

// New returns a service over the store.
func New(s *store.Store) *Service { return &Service{repo: s.Repo()} }

// Error is a contract error with an optional business sub-code.
type Error struct {
	Code    hirakuv1.ErrorCode
	SubCode hirakuv1.ErrorSubCode
}

func (e *Error) Error() string {
	if e.SubCode != hirakuv1.ErrorSubCode_ERROR_SUB_CODE_UNSPECIFIED {
		return e.Code.String() + ": " + e.SubCode.String()
	}
	return e.Code.String()
}

// Handle dispatches one contract method and returns the encoded response.
func (s *Service) Handle(ctx context.Context, method hirakuv1.Method, req []byte) ([]byte, error) {
	switch method {
	case hirakuv1.Method_METHOD_PING:
		if len(req) != 0 {
			return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
		}
		return nil, nil
	case hirakuv1.Method_METHOD_GRADE:
		var request hirakuv1.GradeRequest
		if err := proto.Unmarshal(req, &request); err != nil {
			return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
		}
		response, err := s.grade(ctx, &request)
		if err != nil {
			return nil, err
		}
		return proto.Marshal(response)
	case hirakuv1.Method_METHOD_BUILD_QUEUE:
		var request hirakuv1.BuildQueueRequest
		if err := proto.Unmarshal(req, &request); err != nil {
			return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
		}
		response, err := s.buildQueue(ctx, &request)
		if err != nil {
			return nil, err
		}
		return proto.Marshal(response)
	default:
		return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_NOT_FOUND}
	}
}

// MapError converts domain and storage errors into contract errors.
func MapError(err error) *Error {
	var contract *Error
	if errors.As(err, &contract) {
		return contract
	}
	switch {
	case errors.Is(err, store.ErrNotFound):
		return &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_NOT_FOUND}
	case errors.Is(err, notetype.ErrDuplicateName):
		return &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_BUSINESS_RULE, SubCode: hirakuv1.ErrorSubCode_ERROR_SUB_CODE_DUPLICATE_NAME}
	case errors.Is(err, notetype.ErrTooManyFields):
		return &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_BUSINESS_RULE, SubCode: hirakuv1.ErrorSubCode_ERROR_SUB_CODE_TOO_MANY_FIELDS}
	case errors.Is(err, notetype.ErrMissingTerm), errors.Is(err, notetype.ErrTermNotRequired):
		return &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_BUSINESS_RULE, SubCode: hirakuv1.ErrorSubCode_ERROR_SUB_CODE_MISSING_ROLE}
	case errors.Is(err, store.ErrInvalidNote), errors.Is(err, store.ErrInvalidSetting):
		return &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_BUSINESS_RULE}
	default:
		return &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_STORAGE}
	}
}
